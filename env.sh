create_env() {
env=$(cat <<EOF
      DB_NAME={$database_name_or_user}
      DB_USER={$database_name_or_user}
      DB_PASSWORD={$database_password}

      WP_ENV=development
      WP_HOME=http://{$website_name}
      MIX_WP_HOME=http://example.com
      WP_SITEURL=${WP_HOME}/wp

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
}

echo ${env}

export env