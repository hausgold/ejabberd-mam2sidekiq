# frozen_string_literal: true

class SomeWorker
  include Sidekiq::Worker

  def perform(message, source)
    # Count the messages to stop the test
    $messages += 1
    puts "\n> " + "Process a new XMPP message (##{$messages})\n".blue

    # When the given source is not as expected, rasise
    raise ArgumentError, "Wrong source (#{source})" unless source == 'xmpp-mam'

    # Format the XML in a neat way
    out = StringIO.new
    doc = REXML::Document.new(message)
    formatter = REXML::Formatters::Pretty.new
    formatter.compact = true
    formatter.write(doc, out)
    out = out.string.lines.map { |line| ' ' * 2 + line }.join
    puts "#{out}\n\n"

    # Stop the test when we received at least two jobs
    if $messages >= 2
      sleep 2
      puts "> end-to-end test finished.\n\n".bold.green

      # We need kill our parent process here, because Sidekiq is not designed
      # to be closed from within a job
      pid = `ps -a`.lines.grep(/bundle/).first.strip.split(' ').first
      system("kill -9 #{pid}")
      sleep 1
      system("kill -9 #{pid}")
    end
  end
end
