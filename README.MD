### Discord Ace Perms

### Version
    1.0

### Requirements
    Dead_Discord_API

### Example Role List
    roleList = {
		{1, "group.member"},
		{1, "group.booster"},
		{1, "group.certified"},
		{1, "group.subscriber"},
		{1, "group.moderator"}, 
		{1, "group.owner"}, 
	},

    # Replace the "1" with your discord server role ID's

1. Download Dead_Discord_Ace_Perms
2. Extract the .zip and place the folder in your /resources folder within your FiveM Server
3. Put "add_ace resource.DiscordAcePerms command.add_principal allow" and "add_ace resource.DiscordAcePerms command.remove_principal allow" in your server.cfg
4. Make sure you add "ensure DeadDiscordAcePerms" in your server.cfg
5. Have fun