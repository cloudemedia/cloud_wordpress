module Wordpress
    class TemplateTarJob < Wordpress::TemplateJob 
      
      def perform(template) 
        logger = Logger.new(log_file)
        begin
          logger.info("Template Id:#{template.id} ================") 
            config = Wordpress::Config
            directory = "#{config.template_directory}/#{template.id}"
            mysql_info = {  
                database: template.database, 
                collection_user: template.mysql_user, 
                collection_password: template.mysql_password, 
                collection_host: config.template_mysql_connection_host 
                }
            mysql = Wordpress::Core::Helpers::Mysql.new(mysql_info)
            Net::SSH.start( config.template_host,  config.template_host_user, :password => config.template_host_password, :port => config.template_host_port ) do |ssh|
                logger.info("ssh connected")  
                channel = ssh.open_channel do |ch|  
                  ssh_exec = "cd #{directory} && #{mysql.dump_mysql} && tar cjf #{template.template_tar_file} #{mysql_info[:database]}.sql wordpress"
                  logger.info("#{ssh_exec}") 
                  ch.exec ssh_exec do |ch, success|
                    ch.on_data do |c, data|
                      $stdout.print data  
                    end 
                  end
                end
                channel.wait
            end
        rescue Exception, ActiveJob::DeserializationError => e 
            logger.error("Template Id:#{template.id} ================") 
            logger.error(I18n.t('active_admin.active_job', message: e.message, default: "ActiveJob: #{e.message}"))
            logger.error(e.backtrace.join("\n"))
            nil
        end

      end

      private

      def log_file
        # To create new (and to remove old) logfile, add File::CREAT like;
        #   file = open('foo.log', File::WRONLY | File::APPEND | File::CREAT)
        File.open('log/template_tar_job.log', File::WRONLY | File::APPEND | File::CREAT)
      end

    end
end