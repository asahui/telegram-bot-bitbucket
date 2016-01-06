exports.parseNotification = (msg) ->
  try
    push = msg.push
    repository = msg.repository
    actor = msg.actor
    changes = push.changes
    commits = []
    commits.push commit for commit in change.commits for change in changes
    commit_num = if commits.length > 1 then "#{commits.length} commits" else "a commit"
    trimMessage = (message) ->
        m = message.split('\n')[0]
        message = if m.length <= 60 then m else m.substr(0, 57) + '...'
    tableStr = ''
    for row in commits
      tableStr += "#{row.hash.substring(0, 7)} - #{row.author.user.display_name} - #{trimMessage row.message}\n"
    for row in commits
      tableStr = tableStr.replace row.hash.substr(0, 7),"[#{row.hash.substr(0,7)}](#{row.links.html.href})"
    "*#{actor.display_name}* pushed #{commit_num} to the repository:\n" +
    "[#{repository.full_name}](#{repository.links.html.href})\n" +
    "Here is the commits list:\n" +
    "*Commit* - *Author* - *Message*\n" +
    "*------* - *------* - *-------*\n" +
    "#{tableStr}"
  catch err
    console.log err
    "#{err}"
