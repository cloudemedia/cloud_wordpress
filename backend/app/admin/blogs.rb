if defined?(ActiveAdmin) && defined?(Wordpress::Blog)
    ActiveAdmin.register Wordpress::Blog, as: "Blog" do
        init_controller 
        permit_params  :locale_id,  :name , :description , :cloudflare_id, :domain_id, :admin_user_id, :cname
        menu priority: 50 
        active_admin_paranoia 

        # state_action :install
        state_action :processed
        state_action :has_done
        state_action :publish  
        

        # Scope
        scope :pending
        scope :installed
        scope :processing
        scope :done
        scope :published
        scope :published_today
        scope :published_month

        
        controller do
            def new
                if Server.active.size.blank? || Cloudflare.active.size == 0
                    options = { alert: I18n.t('active_admin.check_server_and_cloudflare',  default: "无可用服务器或者Cloudflare") }
                    redirect_back({ fallback_location: ActiveAdmin.application.root_to }.merge(options)) 
                else
                    super
                end 
            end
            def create   
                params[:blog][:admin_user_id] = current_admin_user.id
                super 
            end
        end 

        member_action :login, method: :put do   
            render "admin/blogs/login.html.erb" , locals: { blog_url: resource.cloudflare_origin, user: resource.user , password: resource.password } 
        end

        member_action :install, method: :put do   
            if resource.templates.size > 1
                render "admin/blogs/install.html.erb"  
            elsif  resource.templates.size == 1
                resource.install_with_template
            else
                options = { alert: I18n.t('active_admin.none_template', lang:  resource.locale.name ,  default: "%{lang}:无可用博客模版") }
                redirect_back({ fallback_location: ActiveAdmin.application.root_to }.merge(options)) 
            end 
        end

        action_item :install, only: :show  do
            unless resource.installed?
                link_to(
                    I18n.t('active_admin.install', default: "安装"),
                    install_admin_blog_path(resource),  
                    method: "put"
                  ) 
            end  
        end

        index do
            if Server.active.size.blank? 
                div class: "flash flash_error" do  
                    link_to "设置服务器", admin_servers_path
                end
            end
            if Cloudflare.active.size == 0 
                div class: "flash flash_error" do  
                    link_to "设置Cloudflare", admin_cloudflares_path
                end
            end
            selectable_column
            id_column   
            column :admin_user  
            column :locale 
            if current_admin_user.admin? 
                column :server  
                column :cloudflare
            end
            column :domain    
            column :origin do |source|
                link_to source.cloudflare_origin, source.cloudflare_origin 
            end
            column :website_url do |source|
                link_to source.online_origin, source.online_origin, target: "_blank" if source.online_origin
            end    
            column :name   
            column :login do |source|
                link_to image_tag("icons/arrows.svg", width: "20", height: "20")  , login_admin_blog_path(source) , target: "_blank" , method: :put , class: "" if source.installed?  
            end 
            column :description    
            tag_column :state, machine: :state   
            column :status    
            column :installed_at
            column :published_at
            actions
        end

        filter :state, as: :check_boxes  
        filter :use_ssl 
        filter :server
        filter :cloudflare
        filter :domain_name
        

        form do |f|
            f.inputs I18n.t("active_admin.blogs.form" , default: "Blog")  do  
                f.input :locale if  current_admin_user.admin? || f.object.pending?
                # f.input :server_id , as: :select, collection: Wordpress::Server.all    
                # f.input :cloudflare_id , as: :select, collection: Wordpress::Cloudflare.all    
                f.input :domain_id,  as: :search_select, 
                            url:  admin_domains_path, 
                            fields: [:name], 
                            display_name: :name, 
                            minimum_input_length: 2     
                f.input :cname
                f.input :name     
                f.input :description    
            end
            f.actions
        end  

        show do
            panel t('active_admin.details', model: resource_class.to_s.titleize) do
                attributes_table_for resource do 
                    row :admin_user  
                    row :locale 
                    row :server  
                    row :cloudflare
                    row :domain    
                    row :origin do |source|
                        link_to source.cloudflare_origin, source.cloudflare_origin
                    end
                    row :website_url do |source|
                        link_to source.online_origin, source.online_origin, target: "_blank" if source.online_origin
                    end 
                    row :name
                    row :description
                    tag_row :state, machine: :state  
                    row :installed_at  
                    row :published_at  
                    row :updated_at 
                    row :created_at   
                end
            end
        end
    end
end