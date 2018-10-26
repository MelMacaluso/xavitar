
#Sources.
source ./credentials.sh
source ./functions.sh
source ./extra.sh

#Intro flow
echo $hr
echo $xavitar_intro
echo $hr
ask_details
recap

# If all inputs are confirmed
if [ "$confirmation" = Y ]
  then
    create_forge_site
    echo "-Created website in Forge."
        if [ "$wordpress_starter_confirmation" != Y ]
            then
            update_forge_site_repository
            echo "-Forge now pulls from your chosen repository.!"
        else
            wp_starter_update_forge_site_repository
            echo "-Forge now pulls from your Wordpress Starter repository."
            wp_starter_update_forge_site_deploy_script
            echo "-Deploy script amended."
        fi
        enable_quick_deploy_forge_site_repository
        echo "-Enabling quick deploy in Forge and deploying."
        create_cloudflare_site
        echo "-Creating MySQL database in Forge"
        create_forge_site_database
        echo "-Website created in Cloudflare."
        get_cloudflare_site_dns
        echo "-Getting cloudflare site dns......"
        get_forge_site_server_ip
        echo "-Getting forge site server ip....."
        delete_cloudflare_site_dns
        echo "-Deleting old DNS records from Cloudflare."
        create_cloudflare_site_dns
        echo "-Creating DNS records according to the ones given by your chosen Forge server provider."
        echo $hr
        echo "DONE, now change your nameservers to the following, sit back and wait for DNS propagation"
        echo $( echo ${cloudflare_response} |  jq -r '.name_servers[0]')
        echo $( echo ${cloudflare_response} |  jq -r '.name_servers[1]')
        echo "If you want to edit your website in forge find it here:"
        echo "https://forge.laravel.com/servers/${client_server_list[$client_server]}/sites/${forge_response_site_id}#/application"

else
    ask_details
    recap
fi