#!/bin/sh
#
# Build script to create .tar.gz package for mail-send installation on OpenIPC
#

set -e

PACKAGE_NAME="openipc-mail-send"
VERSION="${VERSION:-0.1}"
PACKAGE_FULL_NAME="${PACKAGE_NAME}-${VERSION}"
BUILD_DIR="build"
PACKAGE_DIR="${BUILD_DIR}/${PACKAGE_FULL_NAME}"

echo "Building ${PACKAGE_NAME} v${VERSION} package..."

# Clean previous build
rm -rf "${BUILD_DIR}"
mkdir -p "${PACKAGE_DIR}"

# Create directory structure
mkdir -p "${PACKAGE_DIR}/usr/bin"
mkdir -p "${PACKAGE_DIR}/etc/webui"
mkdir -p "${PACKAGE_DIR}/var/www/cgi-bin"

# Copy files
echo "Copying files..."

# mail-send binary -> /usr/bin/
cp mail-send "${PACKAGE_DIR}/usr/bin/"
chmod +x "${PACKAGE_DIR}/usr/bin/mail-send"

# openipc/mail script -> /usr/bin/
cp openipc/mail "${PACKAGE_DIR}/usr/bin/"
chmod +x "${PACKAGE_DIR}/usr/bin/mail"

# openipc/mail.conf.example -> /etc/webui/mail.conf
cp openipc/mail.conf.example "${PACKAGE_DIR}/etc/webui/mail.conf"
chmod 644 "${PACKAGE_DIR}/etc/webui/mail.conf"

# openipc/ext-mail.cgi -> /var/www/cgi-bin/
cp openipc/ext-mail.cgi "${PACKAGE_DIR}/var/www/cgi-bin/"
chmod +x "${PACKAGE_DIR}/var/www/cgi-bin/ext-mail.cgi"

# Copy post-install script
cp openipc/add-mail-menu.sh "${PACKAGE_DIR}/"
chmod +x "${PACKAGE_DIR}/add-mail-menu.sh"

# Create install script
cat > "${PACKAGE_DIR}/install.sh" << 'EOF'
#!/bin/sh
#
# Install script for mail-send on OpenIPC
#

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

echo "Installing mail-send..."

# Copy files to their destinations
cp -f "${SCRIPT_DIR}/usr/bin/mail-send" /usr/bin/
chmod +x /usr/bin/mail-send

cp -f "${SCRIPT_DIR}/usr/bin/mail" /usr/bin/
chmod +x /usr/bin/mail

# Only copy config if it doesn't exist
if [ ! -f /etc/webui/mail.conf ]; then
    mkdir -p /etc/webui
    cp -f "${SCRIPT_DIR}/etc/webui/mail.conf" /etc/webui/
    chmod 644 /etc/webui/mail.conf
    echo "Config file installed: /etc/webui/mail.conf"
else
    echo "Config file already exists, skipping: /etc/webui/mail.conf"
fi

cp -f "${SCRIPT_DIR}/var/www/cgi-bin/ext-mail.cgi" /var/www/cgi-bin/
chmod +x /var/www/cgi-bin/ext-mail.cgi

echo "Adding Mail menu to web interface..."
"${SCRIPT_DIR}/add-mail-menu.sh"

echo ""
echo "Installation complete!"
echo "Edit /etc/webui/mail.conf to configure your mail settings."
EOF
chmod +x "${PACKAGE_DIR}/install.sh"

# Create the tar.gz package
echo "Creating package..."
cd "${BUILD_DIR}"
tar -cvf "${PACKAGE_FULL_NAME}.tar" "${PACKAGE_FULL_NAME}"
gzip -9 "${PACKAGE_FULL_NAME}.tar"
cd ..

# Move package to root
mv "${BUILD_DIR}/${PACKAGE_FULL_NAME}.tar.gz" .

echo ""
echo "Package created: ${PACKAGE_FULL_NAME}.tar.gz"
echo ""
echo "To install on OpenIPC, run:"
echo "  curl -sL URL/${PACKAGE_FULL_NAME}.tar.gz | gunzip | tar x -C /tmp && /tmp/${PACKAGE_FULL_NAME}/install.sh && rm -rf /tmp/${PACKAGE_FULL_NAME}"
