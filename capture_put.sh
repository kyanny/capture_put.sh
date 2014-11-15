# Usage:
#   $ . capture_put.sh
#   $ capture_put URL APPNAME CHARTS_URL
#
# Variables:
#   URL ... New Relic Embedded Chart URL
#     e.g. https://rpm.newrelic.com/public/charts/XXXXXXXXXXX
#   APPNAME ... Application Name
#     e.g. api-rails
#   CHARTS_URL ... New Relic Embedded Charts Tools page
#     e.g. https://rpm.newrelic.com/accounts/XXXXXX/embedded_charts
#
#   S3CFG_PATH ... location of .s3cfg (absolute path)
#     e.g. /home/bitnami/.s3cfg
#   BUCKET_NAME ... S3 bucket name
#     e.g. kyanny-public
#   HTML_TEMPLATE ... Template string of message sent to hipchat
#     e.g. [%s] <a href="%s">[edit]</a> <a href="%s">[delete]</a> <a href="%s">[about]</a><br>
#          <a href="%s"><img src="%s"/></a>
#   JOB_URL ... Jenkins Job URL
#   ABOUT_URL ... About URL
#
#   ROOM_ID ... HipChat room id
#   HIPCHAT_API_TOKEN ... HipChat API Token

capture_put() {
  URL=$1
  APPNAME=$2
  CHARTS_URL=$3
  TIMESTAMP=$(date +%Y-%m-%d-%H-%M-%S)
  FILENAME=$(printf %s-%s.png $APPNAME $TIMESTAMP)
  echo "var page = require('webpage').create();
page.open('${URL}', function(status) {
  page.render('${FILENAME}');
  phantom.exit();
});" > app.js
  phantomjs --ssl-protocol=any --debug=false app.js
  s3cmd -c $S3CFG_PATH put $FILENAME s3://$BUCKET_NAME/$FILENAME
  S3_URL=$(printf https://s3.amazonaws.com/$BUCKET_NAME/$FILENAME)
  TEMPLATE=$(echo $HTML_TEMPLATE | tr ' ' +)
  curl -d room_id="${ROOM_ID}" \
          -d from=Jenkins \
          -d message_format=html \
          -d message=$(printf $TEMPLATE $APPNAME $JOB_URL $CHARTS_URL $ABOUT_URL $URL $S3_URL) \
          -d format=json \
          -d auth_token=$HIPCHAT_API_TOKEN \
          https://api.hipchat.com/v1/rooms/message
}
