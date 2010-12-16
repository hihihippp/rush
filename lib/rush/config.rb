# The config class accesses files in ~/.rush to load and save user preferences.
class Rush::Config
	DefaultPort = 7770

	attr_reader :dir

	# By default, reads from the dir ~/.rush, but an optional parameter allows
	# using another location.
	def initialize(location=nil)
		@dir = Rush::Dir.new(location || "#{ENV['HOME']}/.rush")
		@dir.create
	end

	# History is a flat file of past commands in the interactive shell,
	# equivalent to .bash_history.
	def history_file
		dir['history']
	end

	def save_history(array)
		history_file.write(array.join("\n") + "\n")
	end

	def load_history
		history_file.contents_or_blank.split("\n")
	end

	# The environment file is executed when the interactive shell starts up.
	# Put aliases and your own functions here; it is the equivalent of .bashrc
	# or .profile.
	#
	# Example ~/.rush/env.rb:
	#
	#   server = Rush::Box.new('www@my.server')
	#   myproj = home['projects/myproj/']
	def env_file
		dir['env.rb']
	end

	def load_env
		env_file.contents_or_blank
	end

	# Commands are mixed in to Array and Rush::Entry, alongside the default
	# commands from Rush::Commands.  Any methods here should reference "entries"
	# to get the list of entries to operate on.
	#
	# Example ~/.rush/commands.rb:
	#
	#   def destroy_svn(*args)
	#     entries.select { |e| e.name == '.svn' }.destroy
	#   end
	def commands_file
		dir['commands.rb']
	end

	def load_commands
		commands_file.contents_or_blank
	end

	# Passwords contains a list of username:password combinations used for
	# remote access via rushd.  You can fill this in manually, or let the remote
	# connection publish it automatically.
	def passwords_file
		dir['passwords']
	end

	def passwords
		hash = {}
		passwords_file.lines_or_empty.each do |line|
			user, password = line.split(":", 2)
			hash[user] = password
		end
		hash
	end
	
	def keys_file
	  dir['keys_file']
  end
  
  def generate_keys
    # priv_key = OpenSSL::RSA.new(1024)
    #  pub_key = priv_key.public_key
  end

	# Credentials is the client-side equivalent of passwords.  It contains only
	# one username:password combination that is transmitted to the server when
	# connecting.  This is also autogenerated if it does not exist.
	def credentials_file
		dir['credentials']
	end
	


	def credentials
		credentials_file.lines.first.split(":", 2)
	end

	def save_credentials(user, password)
		credentials_file.write("#{user}:#{password}\n")
	end

	def credentials_user
		credentials[0]
	end

	def credentials_password
		credentials[1]
	end

	def ensure_credentials_exist
		generate_credentials if credentials_file.contents_or_blank == ""
	end

	def generate_credentials
		save_credentials(generate_user, generate_password)
	end

	def generate_user
		generate_secret(4, 8)
	end

	def generate_password
		generate_secret(8, 15)
	end

	def generate_secret(min, max)
		chars = self.secret_characters
		len = rand(max - min + 1) + min
		password = ""
		len.times do |index|
			password += chars[rand(chars.length)]
		end
		password
	end

	def secret_characters
		[ ('a'..'z'), ('1'..'9') ].inject([]) do |chars, range|
			chars += range.to_a
		end
	end

	# ~/.rush/tunnels contains a list of previously created ssh tunnels.  The
	# format is host:port, where port is the local port that the tunnel is
	# listening on.
	def tunnels_file
		dir['tunnels']
	end

	def tunnels
		tunnels_file.lines_or_empty.inject({}) do |hash, line|
			host, port = line.split(':', 2)
			hash[host] = port.to_i
			hash
		end
	end

	def save_tunnels(hash)
		string = ""
		hash.each do |host, port|
			string += "#{host}:#{port}\n"
		end
		tunnels_file.write string
	end
end
