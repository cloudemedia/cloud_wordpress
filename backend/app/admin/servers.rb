ActiveAdmin.register Wordpress::Server,  as: "Server" do
    init_controller    
    actions :all, except: [:destroy, :show] 
    batch_action :destroy, false
    menu priority: 70 , parent: "Settings"  
    permit_params  :name,  :max_size ,:description, :domain, :cloudflare_id,
                   :host, :host_port,:host_user, :host_password, 
                   :mysql_host, :mysql_host_user, :mysql_password, :mysql_port, :installed, :mysql_user
    
    active_admin_paranoia

    controller do
        def update  
            params[:server][:host_password] = resource.host_password if params[:server][:host_password].blank?
            params[:server][:mysql_password] = resource.mysql_password if params[:server][:mysql_password].blank?
            super 
        end
    end

    action_item :test_ssh, only: :edit  do 
            link_to(
                I18n.t('active_admin.test_ssh', default: "SSH连接测试"),
                check_host_admin_server_path(resource),  
                method: "put"
              )  
    end

    action_item :test_mysql, only: :edit  do 
        link_to(
            I18n.t('active_admin.test_mysql', default: "Mysql连接测试"),
            check_mysql_admin_server_path(resource),  
            method: "put"
          )  
    end

    member_action :set_dns, method: :put do   
        begin
            resource.set_dns 
            options = { notice: I18n.t('active_admin.set_dns',  default: "设置成功") }
        rescue Exception  => e   
            options = { alert: e.message }
        end 
        redirect_back({ fallback_location: ActiveAdmin.application.root_to }.merge(options)) 
    end

    member_action :install, method: :put do   
        resource.install 
        options = { notice: I18n.t('active_admin.installing',  default: "已推送安装指令,预计3～7分钟安装完成") }
        redirect_back({ fallback_location: ActiveAdmin.application.root_to }.merge(options)) 
    end

    member_action :check_host, method: :put do   
        if resource.check_host 
            options = { notice: I18n.t('active_admin.connection_ssh_succeeded',  default: "SSH连接成功") }  
        else
            options = { notice: I18n.t('active_admin.connection_ssh_failed',  default: "SSH连接失败") }   
        end
        redirect_back({ fallback_location: ActiveAdmin.application.root_to }.merge(options)) 
    end

    member_action :check_mysql, method: :put do   
        if resource.check_mysql 
            options = { notice: I18n.t('active_admin.connection_mysql_succeeded',  default: "Mysql连接成功") }  
        else
            options = { notice: I18n.t('active_admin.connection_mysql_failed',  default: "Mysql连接失败") }   
        end
        redirect_back({ fallback_location: ActiveAdmin.application.root_to }.merge(options)) 
    end


    index download_links: false  do
        selectable_column
        id_column
        column :host 
        column :cname do |source|
            source.cname
        end
        column :cloudflare 
        column :max_size do |source|
            "#{source.blogs.size}/#{source.max_size}"
        end
        column :name
        column :description   
        column :install do |source|
            if source.installed
                span "已安装", class: "status_tag published"
            else
                link_to I18n.t('active_admin.install',  default: "安装Apahce+php"), install_admin_server_path(source), method: :put  if source.host_status
            end
        end
        column :host_status do |source|
            if source.host_status
               span "OK", class: "status_tag published"
            else
                span "连接失败", class: "status_tag processing"
            end
        end
        column :dns_status 
        column :set_dns do |source|
             link_to I18n.t('active_admin.set_dns',  default: "设置DNS"), set_dns_admin_server_path(source), method: :put  
        end
        column :mysql_status do |source|
            if source.mysql_status
               span "OK", class: "status_tag published"
            else
                span "连接失败", class: "status_tag processing"
            end
        end
        column :created_at
        column :updated_at
        actions
    end

    filter :name  
    filter :host 
    filter :created_at
    filter :updated_at  

    form do |f|
        f.inputs I18n.t("active_admin.php_service.form" , default: "服务器")  do  
          f.input :cloudflare, label: "Cloudflare"    
          f.input :name     
          f.input :description 
          f.input :max_size, label: I18n.t("active_admin.php_service.max_size" , default: "博客最大数量") 
          f.input :host, placeholder: "127.0.0.1" , hint: "安装脚本只支持:Centos 7/8"  
          f.input :host_port, placeholder: "22" 
	      f.input :host_user, placeholder: "root"  
          f.input :host_password , placeholder: "password"  , hint: "密码保存后不显示"    
          hr
          f.input :mysql_host, placeholder: "192.168.10.10"  
          f.input :mysql_host_user, placeholder: "192.168.%.%"  , hint: "root@#{f.object.mysql_host_user.blank? ? "127.0.0.1" : f.object.mysql_host_user}"      
          f.input :mysql_port, placeholder: "3306"   
	      f.input :mysql_user, placeholder: "root" 
          f.input :mysql_password , placeholder: "password"  , hint: "密码保存后不显示"     
        #   f.input :installed   
        end
        f.actions
    end 

    sidebar :tips, only: [:new, :edit] do 
        ul do
           li "博客服务器节点: 创建的博客网站文件所在处"
           li  "Mysql主机信息相对当前服务器填写"
           li  "添加新服务器后可一键安装Apache + PHP环境"
           li  "Mysql服务器需要手工安装" 
        end
        div do
            raw("
            服务器安装完再进行<b>Mysql</b>连接测试<br />
            <br />
            Linode 私有IP设置DEMO:<br />
            vi /etc/sysconfig/network-scripts/ifcfg-eth0:1<br />
            DEVICE=eth0:1 <br />
            IPADDR=192.168.0.0<br />
            PREFIX=17")
        end
    end


end 
    