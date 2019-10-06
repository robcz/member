# Description:
#   Help remember and recall quoteworthy items for your team
#
# Commands:
#   member - Stash a quote worth remembering for later
#   hubot delete <query> - Delete a stashed quote (exact match only on `query`)
#   hubot dump - Export quote stash to file for download
#   hubot lookup <query> - Retrieve any quotes from the stash matching the `query`
#   hubot random - Retrieve a random quote from the stash
#   hubot stats - Retrieve statistics on number of quotes stashed

module.exports = (robot) ->
   S3Upload = require('./s3upload.coffee').S3Upload
   testmode = process.env.HUBOT_MEMBER_TEST_MODE
   QUOTE_CACHE_ID = 'member_quote_cache'
   bot_name = robot.name or robot.alias
   s3_object_name = bot_name + '_quotes.txt'
   s3_config = {
      s3_access_key: process.env.HUBOT_MEMBER_S3_ACCESS_KEY,
      s3_secret_key: process.env.HUBOT_MEMBER_S3_SECRET_KEY,
      s3_bucket: process.env.HUBOT_MEMBER_S3_BUCKET,
      s3_region: process.env.HUBOT_MEMBER_S3_REGION
   }
   quoteCache = []
   memoryRegex = new RegExp("^member (.*)", "i")

   if testmode
      quoteCache = ['(grapes)', 'Orange you glad (i said orange)', '!BANANAS or no?']
      memoryRegex = new RegExp("^memberit (.*)", "i")


   getQuotes = ->
      robot.brain.get(QUOTE_CACHE_ID) or quoteCache
   
   addQuote =(quote) ->
      quotes = getQuotes()
      if quote not in quotes
         quotes.push quote
         robot.brain.set QUOTE_CACHE_ID, quotes

   robot.hear memoryRegex, (res) ->
      newQuote = res.match[1]
      addQuote(newQuote)
      res.reply "Ok I'll remember [#{newQuote}]"

   robot.respond /stats/i, (res) ->
      cacheSize = getQuotes().length
      res.send "I currently remember #{cacheSize} different quotes."

   robot.respond /random/i, (res) ->
      res.send res.random getQuotes()

   robot.respond /lookup (.*)/i, (res) ->
      searchString = res.match[1]
      if searchString.length < 4
         res.send "I'll need you to give me at least more than a few characters here bud!"
      else
         regex = new RegExp(searchString, "gi")
         res.send regex
         quotes = getQuotes()
         quotesFound = 0
         for quote in quotes
            if quote.search(regex) != -1
               quotesFound++
               res.send quote
         if quotesFound == 0
            res.send "I didn't find anything related to #{searchString}"

   robot.respond /dump/i, (res) ->
      s3u = new S3Upload(s3_object_name, bot_name, s3_config, (fileUrl) -> res.reply "File Available at: #{fileUrl}")
      s3u.upload(getQuotes())
      

   robot.respond /delete (.*)/i, (res) ->
      searchString = res.match[1]
      quotes = getQuotes()
      quotes = quotes.filter (quote) -> quote != searchString
      robot.brain.set QUOTE_CACHE_ID, quotes
