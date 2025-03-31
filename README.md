# Schedule I Product Remover

A simple tool to clean up non-favorited products from Schedule I save games.

[Schedule I Product Remover]

## Overview

Schedule I Product Remover is a PowerShell-based utility with a graphical user interface that helps you manage your Schedule I game saves by removing all products that aren't in your favorites list. This helps declutter your game and focus only on the products you care about.

## Features

- **User-friendly interface**: Simple GUI that makes it easy to clean up your save files
- **Automatic save detection**: Automatically finds and selects your Schedule I save folder
- **Backup functionality**: Creates backups of your files before making changes
- **Preview mode**: See what would be removed without actually making changes
- **Detailed logging**: Shows exactly what's happening during the cleanup process

## What It Does

The tool performs the following actions:

1. Reads your `Products.json` file to identify your favorited products
2. Updates the `DiscoveredProducts` list to only include favorited products
3. Updates the `ListedProducts` list to only include favorited products
4. Keeps only the `MixRecipes` that involve your favorited products
5. Keeps only the `ProductPrices` entries for your favorited products
6. Deletes all non-favorited product files from the `CreatedProducts` folder

## Installation

No installation required! Simply download the repository and run the included batch file.

### Requirements

- Windows operating system
- PowerShell 5.1 or higher (included with Windows 10 and 11)
- Schedule I game save files

## Usage

1. Download or clone this repository
2. Double-click the `Run-Product-Cleaner.bat` file
3. The application will open and automatically detect your save folder
4. Adjust the path if needed or use the Browse button to select your save folder
5. Choose whether to create backups and/or preview changes
6. Click "Run Cleanup" to start the process

## Safety Features

- **Backup Creation**: By default, the tool creates a backup of all files before making changes
- **Preview Mode**: You can run the tool in preview mode to see what would be changed without actually modifying any files
- **Validation Checks**: The tool validates your save folder before making any changes

## Troubleshooting

If you encounter any issues:

1. Make sure you're running the batch file as an administrator
2. Check that your Schedule I save folder path is correct
3. Verify that your `Products.json` file has at least one favorited product
4. If all else fails, restore from the backup folder created before changes were made

## License

This project is released under the MIT License - see the LICENSE file for details.

## Disclaimer

This tool is not affiliated with or endorsed by the developers of Schedule I. Use at your own risk. Always back up your save files before using any third-party tools.

## Contributing

Contributions are welcome! Feel free to submit pull requests or open issues if you have suggestions for improvements.

## Acknowledgments

- Thanks to the Schedule I community for inspiration
- Created by Michael Greene
