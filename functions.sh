source ./extra.sh
source ./credentials.sh

#Functions
recap() {
  echo $hr
  echo 'Recap'
  echo $hr
  echo 'Client Server:' $client_server
  echo 'Domain Name:' $domain_name
  if [ "$wordpress_starter_confirmation" != Y ]
    then
      echo 'Repository provider:' $repository_provider
      echo 'Repository branch:' $repository_branch
      echo 'Repository name:' $repository_name
  else
    echo 'Wordpress starter: Yes'
  fi
  echo 'Database name:' ${website_db_name_or_user}
  echo 'Database user:' ${website_db_name_or_user}
  echo 'Database password:' $website_db_password
  echo $hr
  echo 'Confirm? (Y/N)'
  read confirmation
}

ask_details() {
  echo "1) Server you want to host your website exactly as it shows in the following list:"
  for key in "${!client_server_list[@]}"; do echo "-${key}"; done
  read client_server
  echo "2) Your domain name, no protocol or subfolders please. ie. example.com"
  read domain_name
  echo "3) Your MySQL database name (who's gonna be also the user), no spaces or weirdness obviously"
  read website_db_name_or_user
  #Generate db passsword straightaway
  website_db_password=$(generate_password)
  echo "4) Do you want to install the Wordpress Starter? (Y/N)"
  read wordpress_starter_confirmation
  if [ "$wordpress_starter_confirmation" != Y ]
    then
      echo "Who's the repository provider? ie github, gitlab, bitbucket"
      read repository_provider
      echo "What branch shall we track/pull? such as master"
      read repository_branch
      echo "What's the repository name, such as username/repository"
      read repository_name
  fi
}

create_forge_site() {
forge_response=$(curl --silent -X POST "${forge_api_url}/servers/${client_server_list[$client_server]}/sites" \
      -H "Authorization: Bearer ${forge_tokens[$client_server]}" \
      -H "Accept: application/json" \
      -H "Content-Type: application/json" \
      --data '{"domain": "'${domain_name}'","project_type": "php","directory": "/web"}' |  jq '.site')
  forge_response_site_id=$( echo ${forge_response} | jq .id)
}

get_forge_site_server_ip(){
  forge_server_ip=$(curl --silent -X GET "${forge_api_url}/servers/${client_server_list[$client_server]}" \
      -H "Authorization: Bearer ${forge_tokens[$client_server]}}" \
      -H "Accept: application/json" \
      -H "Content-Type: application/json"  | jq -r .server.ip_address)
}

create_forge_site_database(){
    curl --silent -X POST "${forge_api_url}/servers/${client_server_list[$client_server]}/mysql" \
      -H "Authorization: Bearer ${forge_tokens[$client_server]}" \
      -H "Accept: application/json" \
      -H "Content-Type: application/json" \
      --data '{"name": "'${website_db_name_or_user}'","user": "'${website_db_name_or_user}'","password": "'${website_db_password}'"}'
}

update_forge_site_repository() {
  curl --silent -X POST "${forge_api_url}/servers/${client_server_list[$client_server]}/sites/${forge_response_site_id}/git" \
      -H "Authorization: Bearer ${forge_tokens[$client_server]}" \
      -H "Accept: application/json" \
      -H "Content-Type: application/json" \
      --data '{"provider": "'${repository_provider}'","repository": "'${repository_name}'","branch": "'${repository_branch}'"}'
}

wp_starter_update_forge_site_repository() {
  curl --silent -X POST "${forge_api_url}/servers/${client_server_list[$client_server]}/sites/${forge_response_site_id}/git" \
      -H "Authorization: Bearer ${forge_tokens[$client_server]}" \
      -H "Accept: application/json" \
      -H "Content-Type: application/json" \
      --data '{"provider": "'${wordpress_starter[provider]}'","repository": "'${wordpress_starter[name]}'","branch": "'${wordpress_starter[branch]}'"}'
}

enable_quick_deploy_forge_site_repository() {
    curl --silent -X POST "${forge_api_url}/servers/${client_server_list[$client_server]}/sites/${forge_response_site_id}/deployment" \
      -H "Authorization: Bearer ${forge_tokens[$client_server]}" \
      -H "Accept: application/json" \
      -H "Content-Type: application/json"
}

wp_starter_update_forge_site_deploy_script() {
    curl --silent -X PUT "${forge_api_url}/servers/${client_server_list[$client_server]}/sites/${forge_response_site_id}/deployment/script" \
      -H "Authorization: Bearer ${forge_tokens[$client_server]}" \
      -H "Accept: application/json" \
      -H "Content-Type: application/json" \
      --data '{"content": "cd /home/forge/'${domain_name}' \ngit stash \ngit pull origin master\ncomposer install --no-interaction --prefer-dist --optimize-autoloader\necho \"\" | sudo -S service php7.1-fpm reload\ncd web/app/themes/default\nnpm install\nnpm run production"}'
}

create_cloudflare_site() {
cloudflare_response=$(curl --silent -X POST "${cloudflare_api_url}/zones" \
     -H "X-Auth-Key:${cloudflare_api_keys[capeeshe]}" \
     -H "X-Auth-Email:${cloudflare_account_emails[$client_server]}" \
     -H "Content-Type: application/json" \
     --data '{"name":"'${domain_name}'","account":{"id":"'${cloudflare_account_ids[$client_server]}'","name":"'"${cloudflare_account_names[$client_server]}"'"},"jump_start":true}' | jq '.result')
    cloudflare_response_zone_id=$( echo ${cloudflare_response} | jq -r .id)
}

get_cloudflare_site_dns() {
    cloudflare_get_dns_response=$(curl --silent -X GET "${cloudflare_api_url}/zones/${cloudflare_response_zone_id}/dns_records?type=A&name=${domain_name}" \
        -H "X-Auth-Key:${cloudflare_api_keys[$client_server]}" \
        -H "X-Auth-Email:${cloudflare_account_emails[$client_server]}" \
        -H "Content-Type: application/json" \
        | jq -r '.result[].id')

    cloudflare_get_dns_www_response=$(curl --silent -X GET "${cloudflare_api_url}/zones/${cloudflare_response_zone_id}/dns_records?type=A&name=www.${domain_name}" \
        -H "X-Auth-Key:${cloudflare_api_keys[$client_server]}" \
        -H "X-Auth-Email:${cloudflare_account_emails[$client_server]}" \
        -H "Content-Type: application/json" \
        | jq -r '.result[].id')

    cloudflare_get_dns_ids=(${cloudflare_get_dns_response} ${cloudflare_get_dns_www_response})
}

delete_cloudflare_site_dns() {
        for index in "${!cloudflare_get_dns_ids[@]}"; do
        curl --silent -X DELETE "${cloudflare_api_url}/zones/${cloudflare_response_zone_id}/dns_records/${cloudflare_get_dns_ids[index]}" \
          -H "X-Auth-Key:${cloudflare_api_keys[$client_server]}" \
          -H "X-Auth-Email:${cloudflare_account_emails[$client_server]}" \
          -H "Content-Type: application/json" ;
      done
}

create_cloudflare_site_dns() {
          curl --silent -X POST "${cloudflare_api_url}/zones/${cloudflare_response_zone_id}/dns_records" \
            -H "X-Auth-Key:${cloudflare_api_keys[$client_server]}" \
            -H "X-Auth-Email:${cloudflare_account_emails[$client_server]}" \
            -H "Content-Type: application/json" \
            --data '{"type":"A","name":"'${domain_name}'","content":"'${forge_server_ip}'","proxied":true}'

          curl --silent -X POST "${cloudflare_api_url}/zones/${cloudflare_response_zone_id}/dns_records" \
            -H "X-Auth-Key:${cloudflare_api_keys[$client_server]}" \
            -H "X-Auth-Email:${cloudflare_account_emails[$client_server]}" \
            -H "Content-Type: application/json" \
            --data '{"type":"A","name":"www","content":"'${forge_server_ip}'","proxied":true}'
}

#Utils
generate_password() {
  echo $(base64 < /dev/urandom | tr -d 'O0Il1+\/' | head -c 12)
}

export recap
export ask_details
export generate_password
export create_forge_site
export get_forge_site_server_ip
export update_forge_site_repository
export wp_starter_update_forge_site_repository
export create_cloudflare_site
export get_cloudflare_site_dns
export delete_cloudflare_site_dns
export create_cloudflare_site_dns