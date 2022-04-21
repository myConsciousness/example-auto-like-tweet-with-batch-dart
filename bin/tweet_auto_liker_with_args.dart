import 'package:batch/batch.dart';
import 'package:dart_twitter_api/twitter_api.dart';

/// Run this application with command:
/// `dart run bin/tweet_auto_liker_with_args.dart -k YOUR_CONSUMER_KEY -c YOUR_CONSUMER_SECRET -t YOUR_TOKEN -s YOUR_SECRET`
void main(List<String> args) => BatchApplication(
      args: args,
      argsConfigBuilder: (parser) => parser
        ..addOption('apiConsumerKey', abbr: 'k')
        ..addOption('apiConsumerSecret', abbr: 'c')
        ..addOption('apiToken', abbr: 't')
        ..addOption('apiSecret', abbr: 's'),
      onLoadArgs: (args) {
        final twitter = TwitterApi(
          client: TwitterClient(
            consumerKey: args['apiConsumerKey'],
            consumerSecret: args['apiConsumerSecret'],
            token: args['apiToken'],
            secret: args['apiSecret'],
          ),
        );

        // Add instance of TwitterApi to shared parameters.
        // This instance can be used from anywhere in this batch application as a singleton instance.
        return {'twitterApi': twitter};
      },
      jobs: [AutoLikeTweetJob()],
    )..run();

class AutoLikeTweetJob implements ScheduledJobBuilder {
  @override
  ScheduledJob build() => ScheduledJob(
        name: 'Auto Like Tweet Job',
        schedule: CronParser('* */1 * * *'), // Will be executed hourly
        steps: [
          Step(
            name: 'Auto Like Tweet Step',
            task: AutoLikeTweetTask(),
          ),
        ],
      );
}

class AutoLikeTweetTask extends Task<AutoLikeTweetTask> {
  @override
  Future<void> execute(ExecutionContext context) async {
    // Get TwitterApi instance from shared parameters.
    final TwitterApi twitter = context.sharedParameters['twitterApi'];

    try {
      // Search for tweets
      final tweets =
          await twitter.tweetSearchService.searchTweets(q: '#coding');

      int count = 0;
      for (final status in tweets.statuses!) {
        if (count >= 10) {
          // Stop after 10 auto-likes
          return;
        }

        // Auto like the tweet
        await twitter.tweetService.createFavorite(id: status.idStr!);
        count++;
      }
    } catch (e, s) {
      log.error('Failed to like tweet', e, s);
    }
  }
}
