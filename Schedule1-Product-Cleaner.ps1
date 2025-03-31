#
# Schedule I Product Cleaner
# This script provides a GUI to remove non-favorited products from Schedule I save games
#

# Add Windows Forms assembly
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing
[System.Windows.Forms.Application]::EnableVisualStyles()

# Function to display script progress in the output box
function Write-Status {
    param(
        [string]$Message,
        [string]$Type = "INFO" # INFO, SUCCESS, ERROR, WARNING
    )
    
    $timestamp = Get-Date -Format "HH:mm:ss"
    $outputLine = "[$timestamp] $Message"
    
    # Determine color based on message type
    switch ($Type) {
        "SUCCESS" { $color = "Green" }
        "ERROR" { $color = "Red" }
        "WARNING" { $color = "Yellow" }
        default { $color = "White" }
    }
    
    # Add text with color
    $outputBox.SelectionColor = [System.Drawing.Color]::$color
    $outputBox.AppendText("$outputLine`r`n")
    $outputBox.SelectionStart = $outputBox.Text.Length
    $outputBox.ScrollToCaret()
    
    # Force UI update
    [System.Windows.Forms.Application]::DoEvents()
}

# Function to clean up non-favorited products
function Clean-Products {
    param(
        [string]$SaveGamePath,
        [bool]$BackupFiles = $true,
        [bool]$PreviewOnly = $false
    )
    
    try {
        # Validate path
        if (-not (Test-Path "$SaveGamePath\Products\Products.json")) {
            Write-Status "Products.json not found at the specified path. Please provide the correct SaveGame path." -Type "ERROR"
            return $false
        }

        Write-Status "Starting cleanup process..."
        
        # Read the Products.json file
        $productsJsonPath = "$SaveGamePath\Products\Products.json"
        $productsJson = Get-Content -Path $productsJsonPath -Raw | ConvertFrom-Json
        
        # Get the list of favorited products
        $favoritedProducts = $productsJson.FavouritedProducts
        
        if ($favoritedProducts.Count -eq 0) {
            Write-Status "No favorited products found in the save file." -Type "WARNING"
            return $false
        }
        
        Write-Status "Found $($favoritedProducts.Count) favorited products"
        Write-Status "Favorited products: $($favoritedProducts -join ', ')"
        
        # Count items to be removed
        $nonFavoritedDiscovered = $productsJson.DiscoveredProducts | Where-Object { $favoritedProducts -notcontains $_ }
        $nonFavoritedListed = $productsJson.ListedProducts | Where-Object { $favoritedProducts -notcontains $_ }
        $nonFavoritedRecipes = $productsJson.MixRecipes | Where-Object {
            $favoritedProducts -notcontains $_.Product -and 
            $favoritedProducts -notcontains $_.Mixer -and 
            $favoritedProducts -notcontains $_.Output
        }
        $nonFavoritedPrices = $productsJson.ProductPrices | Where-Object {
            $favoritedProducts -notcontains $_.String
        }
        
        Write-Status "Found items to remove:"
        Write-Status "- $($nonFavoritedDiscovered.Count) products from DiscoveredProducts"
        Write-Status "- $($nonFavoritedListed.Count) products from ListedProducts"
        Write-Status "- $($nonFavoritedRecipes.Count) recipes from MixRecipes"
        Write-Status "- $($nonFavoritedPrices.Count) prices from ProductPrices"
        
        # Check for product files to delete
        $createdProductsPath = "$SaveGamePath\Products\CreatedProducts"
        $productFiles = Get-ChildItem -Path $createdProductsPath -Filter "*.json"
        $filesToDelete = $productFiles | Where-Object { $favoritedProducts -notcontains $_.BaseName }
        
        Write-Status "Found $($filesToDelete.Count) product files to delete"
        
        if ($PreviewOnly) {
            Write-Status "Preview mode - no changes were made." -Type "SUCCESS"
            return $true
        }
        
        # Backup the original file if requested
        if ($BackupFiles) {
            $backupFolder = "$SaveGamePath\Products\Backup_$(Get-Date -Format 'yyyyMMdd_HHmmss')"
            New-Item -ItemType Directory -Path $backupFolder -Force | Out-Null
            
            # Backup Products.json
            Copy-Item -Path $productsJsonPath -Destination "$backupFolder\Products.json"
            
            # Backup product files
            foreach ($file in $filesToDelete) {
                Copy-Item -Path $file.FullName -Destination "$backupFolder\$($file.Name)"
            }
            
            Write-Status "Created backup at $backupFolder" -Type "SUCCESS"
        }
        
        # Update DiscoveredProducts to only include favorited products
        $productsJson.DiscoveredProducts = $favoritedProducts
        
        # Update ListedProducts to keep only favorited products from the existing list
        $filteredListedProducts = $productsJson.ListedProducts | Where-Object { $favoritedProducts -contains $_ }
        $productsJson.ListedProducts = $filteredListedProducts
        
        # Filter MixRecipes to only include recipes involving favorited products
        $filteredRecipes = $productsJson.MixRecipes | Where-Object {
            $favoritedProducts -contains $_.Product -or 
            $favoritedProducts -contains $_.Mixer -or 
            $favoritedProducts -contains $_.Output
        }
        $productsJson.MixRecipes = $filteredRecipes
        
        # Filter ProductPrices to only include favorited products
        $filteredPrices = $productsJson.ProductPrices | Where-Object {
            $favoritedProducts -contains $_.String
        }
        $productsJson.ProductPrices = $filteredPrices
        
        # Save the updated Products.json
        $productsJson | ConvertTo-Json -Depth 10 | Set-Content -Path $productsJsonPath
        Write-Status "Updated Products.json file" -Type "SUCCESS"
        
        # Delete non-favorited product files
        $deletedCount = 0
        foreach ($file in $filesToDelete) {
            Remove-Item $file.FullName -Force
            $deletedCount++
            
            # Update UI every 10 files
            if ($deletedCount % 10 -eq 0) {
                Write-Status "Deleted $deletedCount of $($filesToDelete.Count) files..."
            }
        }
        
        Write-Status "Cleanup complete! Kept $($favoritedProducts.Count) favorited products and removed $($filesToDelete.Count) non-favorited product files." -Type "SUCCESS"
        return $true
        
    } catch {
        Write-Status "Error: $_" -Type "ERROR"
        Write-Status "Script execution failed. Some changes may not have been applied." -Type "ERROR"
        return $false
    }
}

# Create the main form
$form = New-Object System.Windows.Forms.Form
$form.Text = 'Schedule I Product Cleaner'
$form.Size = New-Object System.Drawing.Size(600, 500)
$form.StartPosition = 'CenterScreen'
$form.FormBorderStyle = 'FixedDialog'
$form.MaximizeBox = $false
$form.Icon = [System.Drawing.Icon]::ExtractAssociatedIcon([System.Diagnostics.Process]::GetCurrentProcess().MainModule.FileName)

# Create a label for the title
$titleLabel = New-Object System.Windows.Forms.Label
$titleLabel.Location = New-Object System.Drawing.Point(20, 20)
$titleLabel.Size = New-Object System.Drawing.Size(560, 30)
$titleLabel.Text = 'Schedule I Product Cleaner'
$titleLabel.Font = New-Object System.Drawing.Font("Arial", 16, [System.Drawing.FontStyle]::Bold)
$form.Controls.Add($titleLabel)

# Create a label for instructions
$instructionLabel = New-Object System.Windows.Forms.Label
$instructionLabel.Location = New-Object System.Drawing.Point(20, 60)
$instructionLabel.Size = New-Object System.Drawing.Size(560, 40)
$instructionLabel.Text = 'This tool will remove all non-favorited products from your Schedule I save game. Select your save game folder below.'
$form.Controls.Add($instructionLabel)

# Create path label
$pathLabel = New-Object System.Windows.Forms.Label
$pathLabel.Location = New-Object System.Drawing.Point(20, 110)
$pathLabel.Size = New-Object System.Drawing.Size(150, 20)
$pathLabel.Text = 'Save Game Folder:'
$form.Controls.Add($pathLabel)

# Create path input field
$pathTextBox = New-Object System.Windows.Forms.TextBox
$pathTextBox.Location = New-Object System.Drawing.Point(20, 130)
$pathTextBox.Size = New-Object System.Drawing.Size(450, 20)

# Try to automatically find the first save folder
$baseSavePath = [System.Environment]::ExpandEnvironmentVariables("%USERPROFILE%\AppData\LocalLow\TVGS\Schedule I\Saves")
$defaultPath = $baseSavePath

if (Test-Path $baseSavePath) {
    # Get the first directory in the Saves folder (typically the Steam ID folder)
    $steamIdFolder = Get-ChildItem -Path $baseSavePath -Directory | Select-Object -First 1
    
    if ($steamIdFolder) {
        # Check if there are save game folders inside the Steam ID folder
        $saveGameFolder = Get-ChildItem -Path $steamIdFolder.FullName -Directory | Select-Object -First 1
        
        if ($saveGameFolder) {
            $defaultPath = $saveGameFolder.FullName
        } else {
            $defaultPath = $steamIdFolder.FullName
        }
    }
}

$pathTextBox.Text = $defaultPath
$form.Controls.Add($pathTextBox)

# Create browse button
$browseButton = New-Object System.Windows.Forms.Button
$browseButton.Location = New-Object System.Drawing.Point(480, 130)
$browseButton.Size = New-Object System.Drawing.Size(80, 23)
$browseButton.Text = 'Browse...'
$browseButton.Add_Click({
    $folderBrowser = New-Object System.Windows.Forms.FolderBrowserDialog
    $folderBrowser.Description = 'Select your Schedule I save game folder'
    $folderBrowser.RootFolder = 'MyComputer'
    $folderBrowser.SelectedPath = $pathTextBox.Text
    
    if ($folderBrowser.ShowDialog() -eq 'OK') {
        $pathTextBox.Text = $folderBrowser.SelectedPath
    }
})
$form.Controls.Add($browseButton)

# Create backup checkbox
$backupCheckbox = New-Object System.Windows.Forms.CheckBox
$backupCheckbox.Location = New-Object System.Drawing.Point(20, 160)
$backupCheckbox.Size = New-Object System.Drawing.Size(250, 20)
$backupCheckbox.Text = 'Create backup before making changes'
$backupCheckbox.Checked = $true
$form.Controls.Add($backupCheckbox)

# Create preview checkbox
$previewCheckbox = New-Object System.Windows.Forms.CheckBox
$previewCheckbox.Location = New-Object System.Drawing.Point(280, 160)
$previewCheckbox.Size = New-Object System.Drawing.Size(250, 20)
$previewCheckbox.Text = 'Preview only (no changes)'
$previewCheckbox.Checked = $false
$form.Controls.Add($previewCheckbox)

# Create output label
$outputLabel = New-Object System.Windows.Forms.Label
$outputLabel.Location = New-Object System.Drawing.Point(20, 190)
$outputLabel.Size = New-Object System.Drawing.Size(150, 20)
$outputLabel.Text = 'Output:'
$form.Controls.Add($outputLabel)

# Create status output
$outputBox = New-Object System.Windows.Forms.RichTextBox
$outputBox.Location = New-Object System.Drawing.Point(20, 210)
$outputBox.Size = New-Object System.Drawing.Size(540, 180)
$outputBox.ReadOnly = $true
$outputBox.BackColor = [System.Drawing.Color]::Black
$outputBox.ForeColor = [System.Drawing.Color]::White
$outputBox.Font = New-Object System.Drawing.Font("Consolas", 9)
$form.Controls.Add($outputBox)

# Create run button
$runButton = New-Object System.Windows.Forms.Button
$runButton.Location = New-Object System.Drawing.Point(230, 410)
$runButton.Size = New-Object System.Drawing.Size(120, 30)
$runButton.Text = 'Run Cleanup'
$runButton.BackColor = [System.Drawing.Color]::FromArgb(0, 120, 215)
$runButton.ForeColor = [System.Drawing.Color]::White
$runButton.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
$runButton.Add_Click({
    $outputBox.Clear()
    $savePath = $pathTextBox.Text
    $createBackup = $backupCheckbox.Checked
    $previewOnly = $previewCheckbox.Checked
    
    if ([string]::IsNullOrWhiteSpace($savePath)) {
        Write-Status "Please enter a valid save game path." -Type "ERROR"
        return
    }
    
    if ($previewOnly) {
        Write-Status "PREVIEW MODE: No changes will be made" -Type "WARNING"
    }
    
    # Disable the button while processing
    $runButton.Enabled = $false
    $runButton.Text = "Processing..."
    
    # Run the cleanup
    $result = Clean-Products -SaveGamePath $savePath -BackupFiles $createBackup -PreviewOnly $previewOnly
    
    # Re-enable the button
    $runButton.Enabled = $true
    $runButton.Text = "Run Cleanup"
    
    if ($result) {
        Write-Status "Operation completed successfully." -Type "SUCCESS"
    }
})
$form.Controls.Add($runButton)

# Create a status bar
$statusBar = New-Object System.Windows.Forms.StatusStrip
$statusBarLabel = New-Object System.Windows.Forms.ToolStripStatusLabel
$statusBarLabel.Text = "Ready"
$statusBar.Items.Add($statusBarLabel)
$form.Controls.Add($statusBar)

# Write initial status
Write-Status "Application started. Select a save game folder and click 'Run Cleanup'."

# Show the form
$form.ShowDialog()
