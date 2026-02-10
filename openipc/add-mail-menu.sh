#!/bin/sh
#
# Script to add Mail menu item to OpenIPC header.cgi
# Adds Mail entry after Telegram in the Extensions dropdown menu
#

HEADER_FILE="/var/www/cgi-bin/p/header.cgi"

# Check if header file exists
if [ ! -f "$HEADER_FILE" ]; then
    echo "Error: $HEADER_FILE not found"
    exit 1
fi

# Check if Mail menu already exists
if grep -q 'ext-mail.cgi' "$HEADER_FILE"; then
    echo "Mail menu item already exists in $HEADER_FILE"
    exit 0
fi

# Check if Telegram menu exists (we'll add Mail after it)
if ! grep -q 'ext-telegram.cgi' "$HEADER_FILE"; then
    echo "Error: Telegram menu item not found in $HEADER_FILE"
    exit 1
fi

# Create backup
cp "$HEADER_FILE" "${HEADER_FILE}.bak"
echo "Backup created: ${HEADER_FILE}.bak"

# Add Mail menu item after Telegram
sed -i 's|<li><a class="dropdown-item" href="ext-telegram.cgi">Telegram</a></li>|<li><a class="dropdown-item" href="ext-telegram.cgi">Telegram</a></li>\n\t\t\t\t\t\t\t<li><a class="dropdown-item" href="ext-mail.cgi">Mail</a></li>|' "$HEADER_FILE"

# Verify the change was made
if grep -q 'ext-mail.cgi' "$HEADER_FILE"; then
    echo "Successfully added Mail menu item to $HEADER_FILE"
    exit 0
else
    echo "Error: Failed to add Mail menu item"
    # Restore backup
    mv "${HEADER_FILE}.bak" "$HEADER_FILE"
    echo "Backup restored"
    exit 1
fi
