# Backend challenge: MTG

Welcome to my code challenge building a command-line tool to query the
https://api.magicthegathering.io/v1/cards endpoint. The solution uses only Ruby
stdlib (except for RSpec and companion helpers).

## Usage

Just run `$ bundle exec ruby bin/mtg_api.rb` and it will start printing the
names of the cards according to the three requested features one after the other.
Also, you can use the `--interactive` switch to let the tool ask for a keypress
after each set.

The specs weren't clear about which information of each card should be listed,
but as there was a lot of data for each one I've chosen to just print its
name.

## Internals

The `MtgAPI` class acts as a thin
[Facade](https://en.wikipedia.org/wiki/Facade_pattern) around the endpoint API
and internally works with `net/http`.

`CardRepository` allows querying all cards in one go with `#all` or the more
specific requested queries `#by_set` and `#by_set_and_rarity`. Beware that
after the first data load the results are cached. Data request strategy is
abstracted with the injected dependency to allow for different retrieval
options (a bit over-architected when there is only one I admit but keep
reading).

`ParallelStrategy` is the final retrieval strategy as explained next.

## Parallelization

A first simple solution to this problem will be to sequentially request page
after page at the endpoint. Although MRI has the GIL (which multiple threads to
be running Ruby code at the same time), we are most of the time waiting for I/O
to complete so there is a lot be gain by parallelization.

The next improvement in complexity will be to start a group of N `Threads` to
query the endpoint concurrently. When every thread in the group finishes, we
gather all the responses and then proceed with the next block. According to my
tests, this improves performance by more than 50%.

A still better approach it is to use a `ThreadPool` of workers. This way,
when a worker finishes its request, it can immediately grab another piece of
work and is not waiting for the slowest one in the group to finish. This cuts
the total time another 25%.

Please also note that `MtgAPI` works with a `ConnectionPool` so each worker
checkouts and returns its HTTPS connection from it. This way, we avoid the TCP
and SSL setup time penalty for each new page request, as we can use the HTTP
KeepAlive feature.

I have hand-crafted both implementations just for this challenge with a bit of
inspiration from https://rossta.net/blog/a-ruby-antihero-thread-pool.html and
https://docs.ruby-lang.org/en/master/Bundler/ConnectionPool.html. I will never
ever do this for production code, as there are well know ruby concurrency gems
that are battle-tested (but you said bonus points!).

## Testing

Use `$ bundle exec rspec` to run the test suite.

Testing code that interacts with an external API can be complex. For `MtgAPI`
I've chosen to do a few integration specs with the
[VCR gem](https://github.com/vcr/vcr). VCR will record the first
interaction with the API and store it in a *cassette* for later playback.

If the payload was smaller and simpler I might have considered using directly
WebMock (https://github.com/bblimke/webmock) to stub requests via code. IMHO
mocking directly `net/http` can result in brittle tests very fast.

`CardRepository` and `ParallelStrategy` are good candidates for direct mocking
of dependencies and I just used `Rspec` with its companion mocking library.

## API Rate-Limit

In the API [documentation](https://docs.magicthegathering.io/) it states:

> Third-party applications are currently throttled to 5000 requests per hour.
> As this API continues to age, the rate limits may be updated to provide
> better performance to users

For sure there was an update becase `Ratelimit-Remaining` starts at 1000 and,
after simple examination the moving window is much shorter than an hour (my
guess is around 5min). When trying to exhaust the service, it looks like the
Heroku request queue fills first and it starts responding with `503 -
Unavailable service` much earlier than when you get low on the
`Ratelimit-Remaining` number (try hitting the API with more than 100 concurrent
threads and see).

In this situation, and being in the dark exactly how the Heroku queue operates
(or if it is in real a DDoS mitigation attempt) is very complex to implement a
**really working scheme for this**. My first guess was something like:

```sleep(COOLDOWN_TIME) if response['Ratelimit-Remaining'] < 50```

after procesing a response. But while tried to test it, `<503>` appeared before
always so I've removed it from the source because it was too arbitrary.

## Have you ever been to the dark side of the moon?

There is a secret `dark_side_of_the_moon` branch in this repo that..

### Has by default a nice progress bar

With the help of https://github.com/piotrmurach/tty-progressbar it allows you
to know which is the current progress and estimated time remaining of the
workload. Because who likes waiting just watching a blank screen?

### Allows to switch to all retrieval strategies with switches

You can use `--sequential-requests`a and `--block-requests` to switch among
them. It is interesting to run them with `time` to compare performance:

```
$ time bundle exec ruby bin/mtg_cards.rb --sequential-requests > /dev/null
real    8m50.488s
user    0m10.455s
sys     0m2.508s

$ time bundle exec ruby bin/mtg_cards.rb --block-requests > /dev/null
real    4m5.008s
user    0m11.321s
sys     0m2.225s

$ time bundle exec ruby bin/mtg_cards.rb > /dev/null
real    2m59.579s
user    0m10.291s
sys     0m1.746s
```

### Allows to configure the thread and shared connection pool size

Use `--workers=XX` to spin up a specific number of workers to fine-tune performance.

### Graphs the performance of different ThreadPool sizes

Running `ruby bin/iterate_workers.rb` will start iterating over different
worker's size to call and benchmark `mtg_cards.rb` performance. After storing
all the results it will produce a graph in the terminal like this:

```
5 : ▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇ 546.01
7 : ▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇ 420.08
9 : ▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇ 371.74
11: ▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇ 301.36
13: ▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇ 264.72
15: ▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇ 248.12
17: ▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇ 232.01
19: ▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇ 226.74
21: ▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇ 237.08
23: ▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇ 220.26
25: ▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇ 201.19
27: ▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇ 208.45
29: ▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇ 226.12
31: ▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇ 189.32
33: ▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇ 209.48
35: ▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇ 181.72
37: ▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇ 215.10
39: ▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇ 201.86
41: ▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇ 180.50
43: ▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇ 181.38
45: ▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇ 222.89
```

For this to work you need [termgraph](https://github.com/mkaz/termgraph),
that can be installed via `$ pip3 install termgraph`.
