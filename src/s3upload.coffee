class exports.S3Upload

   aws = require('aws-sdk')
   s3 = {}


   constructor: (file_name, export_label, s3_config, onSuccess) ->
      @file_name = file_name
      @export_label = export_label
      @s3_config = s3_config
      @s3 = @initializeS3(aws)
      @onSuccess = onSuccess
      @fileUrl = "http://" + @s3_config.s3_bucket + ".s3-website-" + @s3_config.s3_region + ".amazonaws.com/" + @file_name

   validS3Config: () ->
      unless @s3_config.s3_access_key? 
         console.log "Empty s3 access key -- Unable to upload"
         return false
      unless @s3_config.s3_secret_key? 
         console.log "Empty s3 secret key -- Unable to upload"
         return false
      unless @s3_config.s3_bucket? 
         console.log "Empty s3 bucket -- Unable to upload"
         return false
      unless @s3_config.s3_region? 
         console.log "Empty s3 region -- Unable to upload"
         return false
      true
   
   upload: (data) ->
      unless @validS3Config()
         return
      file = @flattenData(data)
      @uploadToS3(file)

   uploadToS3: (file) ->
      if s3 = {}
         s3 = @initializeS3(aws)
      s3Params = @generateS3Parameters(file)
      s3.putObject(s3Params, (e,d) => 
         if e? console.log e
         else @onSuccess @fileUrl
      )


   generateS3Parameters: (file) ->
      s3Params = {
         Bucket: @s3_config.s3_bucket,
         Key: @file_name,
         ACL: 'public-read',
         ContentType: 'text/plain',
         Body: file
      }

   initializeS3: (aws) ->
      awsConfiguration = {
         region: @s3_config.s3_region,
         credentials: {
            accessKeyId: @s3_config.s3_access_key,
            secretAccessKey: @s3_config.s3_secret_key
         }
      }
      aws.config.update(awsConfiguration)
      new aws.S3()
    
   flattenData: (data) ->
      flatData = '------------------' + @export_label + ' exported: ' + new Date()
      flatData += '\n' + item for item in data
      flatData

#module.exports = class S3Upload

if require.main == module
   console.log "Running standalone"
   quotes = ['(grapes)', 'Orange?', 'A "watermelon"', 'Notice pineapples?']
   bot_name = 'member-test' # use robot.name or robot.alias
   s3_object_name = bot_name + '_quotes.txt'
   s3_config = {
      s3_access_key: process.env.HUBOT_MEMBER_S3_ACCESS_KEY,
      s3_secret_key: process.env.HUBOT_MEMBER_S3_SECRET_KEY,
      s3_bucket: process.env.HUBOT_MEMBER_S3_BUCKET,
      s3_region: process.env.HUBOT_MEMBER_S3_REGION
   }
   s3u = new S3Upload(s3_object_name, bot_name, s3_config, (fileUrl) -> console.log "File Available at: #{fileUrl}")
   s3u.upload(quotes)
