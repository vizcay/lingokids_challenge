require 'tty-progressbar'

module Progressbar
  BAR = "[:bar] :percent | Elapsed: :elapsed | ETA: :eta"

  def progressbar_start(total:)
    @progress = TTY::ProgressBar.new(BAR, head: '>', total: total)
    @progress.start
    @progress.advance
  end

  def progressbar_advance
    @progress.advance
  end
end
