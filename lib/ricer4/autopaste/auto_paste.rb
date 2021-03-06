module Ricer4::Plugins::Paste
  class AutoPaste < Ricer4::Plugin
    
    connector_is :irc
    
    priority_is 100
    
    has_setting name: :limit, type: :integer, scope: :server, permission: :ircop, default: 12, min: 3

    def limit
      get_server_setting(server, :limit)
    end
    
    ### One thread to rule them all
    # def ricer_on_global_startup
      # #bot.log.debug("AutoPaste#ricer_on_global_startup")
      # threaded {
        # loop {
          # # After some time...
          # sleep 4.seconds
          # #bot.log.debug("AutoPaste#flush_servers")
          # limit = self.limit
          # servers.each do |server|
            # if server.online?
              # begin
                # # Check each server
                # flush_server(server, server.connection, limit)
              # rescue StandardError => e
                # bot.log.exception(e)
              # end
            # end
          # end
        # }
      # }
    # end
    
    ### After a privmsg, check if we should flush instantly (thx dloser) 
    def plugin_init
      # arm_subscribe("ricer/command/finished") do
        # server.connection.queue_with_lock do |queues|
          # queue = queues[sender]
          # if queue && (queue.length >= limit)
            # flush_user(sender, queue)
          # end
        # end
      # end
    end
    
    ### Call this for each server
    def flush_server(server, connection, limit)
      return unless server.connected?
      if connection.respond_to?(:queue_with_lock) # has queues?
        # bot.log.debug("AutoPaste#flush_server(#{server.display_name})")
        connection.queue_with_lock do |queues| # lock and check queue
          unless queues.nil?
            queues.each do |user,queue| # for each user
              if user.is_a?(Ricer4::User)
                if queue.length >= limit # should flush?
                  flush_user(user, queue)
                end
              end
            end
          end
        end
      end
    end
    
    ### do it!
    def flush_user(user, queue)
      begin
        send_queue_as_pastebin(user, queue)
      rescue StandardError => e
        bot.log.exception(e)
      end
    end
    
    ### Flush it!
    def send_queue_as_pastebin(user, queue)
      bot.log.debug("AutoPaste#send_queue_as_pastebin(#{user.display_name})")
      # Fetch and purge user queue
      server = user.server
      messages = queue.lines
      # Let ricer know that the messages have been sent.
      messages.each{|m|server.ricer_replies_to(m)}
      # Deliver via pastebin
      build_and_send_pastepin(messages)
      # Flush queue
      queue.flush
    end
    
    ### Build the autopaste and send it
    def build_and_send_pastepin(messages)
      # XXX: start a thread with a new message scope (ugly)
      threaded {
        # The message that caused all this!
        Thread.current[:ricer_message] = messages.first
        Thread.current[:ricer_user] = sender
        # Inform_user
        sender.localize!.send_message(t(:msg_autopasting, :count => messages.length))
        # Paste it!
        get_plugin('Paste/Paste').
          send_pastebin(
            autopaste_title(messages),
            autopaste_message(messages),
            messages.length,
            'text',
            'ricer4.plugins.paste.auto_paste.msg_autopasted',
          )
      }
    end
    
    ### Paste title
    def autopaste_title(messages)
      t(:pasteout_title,
        user: user.name,
        date: l(Time.now),
        command: messages.first.args[1],
      )
    end

    ### Paste content
    def autopaste_message(messages)
      messages.map(&:reply_data).join("\n")
    end
    
  end
end
