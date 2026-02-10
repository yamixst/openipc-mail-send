#!/bin/sh
#
# Script to add Email menu item to OpenIPC header.cgi
# Adds Email entry after Telegram in the Extensions dropdown menu
#

HEADER_FILE="/var/www/cgi-bin/p/header.cgi"

# Check if header file exists
if [ ! -f "$HEADER_FILE" ]; then
    echo "Error: $HEADER_FILE not found"
    exit 1
fi

# Check if Email menu already exists
if grep -q 'ext-email.cgi' "$HEADER_FILE"; then
    echo "Email menu item already exists in $HEADER_FILE"
    exit 0
fi

# Check if Telegram menu exists (we'll add Email after it)
if ! grep -q 'ext-telegram.cgi' "$HEADER_FILE"; then
    echo "Error: Telegram menu item not found in $HEADER_FILE"
    exit 1
fi

# Create backup
cp "$HEADER_FILE" "${HEADER_FILE}.bak"
echo "Backup created: ${HEADER_FILE}.bak"

# Add Email menu item after Telegram
sed -i 's|<li><a class="dropdown-item" href="ext-telegram.cgi">Telegram</a></li>|<li><a class="dropdown-item" href="ext-telegram.cgi">Telegram</a></li>\n\t\t\t\t\t\t\t<li><a class="dropdown-item" href="ext-email.cgi">Email</a></li>|' "$HEADER_FILE"

# Verify the change was made
if grep -q 'ext-email.cgi' "$HEADER_FILE"; then
    echo "Successfully added Email menu item to $HEADER_FILE"
    exit 0
else
    echo "Error: Failed to add Email menu item"
    # Restore backup
    mv "${HEADER_FILE}.bak" "$HEADER_FILE"
    echo "Backup restored"
    exit 1
fi
