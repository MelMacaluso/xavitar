env=$( cat <<EOF
DB_NAME=$website_db_name_or_user
DB_USER=$website_db_name_or_user
DB_PASSWORD=$website_db_password

WP_ENV=development
WP_HOME=http://$domain_name
MIX_WP_HOME=http://$domain_name
WP_SITEURL=http://$domain_name/wp

ACF_PRO_KEY=$acf_pro_key

# Generate your keys here: https://roots.io/salts.html
AUTH_KEY='generateme'
SECURE_AUTH_KEY='generateme'
LOGGED_IN_KEY='generateme'
NONCE_KEY='generateme'
AUTH_SALT='generateme'
SECURE_AUTH_SALT='generateme'
LOGGED_IN_SALT='generateme'
NONCE_SALT='generateme'
EOF
)

export env