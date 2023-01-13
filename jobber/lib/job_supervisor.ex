defmodule Jobber.JobSupervisor do
  @moduledoc """
  Intermediary process used to prevent cascading failures due to a single 
  rapidly failing job.

  This supervisor will take care of supervising and restarting a single job, 
  but it is itself supervised by the main job runner in a :temporary way, so that 
  if this supervisor crashes, it won't be restarted, thus not being able to take
  main job runner supervisor down.
  """

  use Supervisor, restart: :temporary

  def start_link(args) do
    Supervisor.start_link(__MODULE__, args)
  end

  def init(args) do
    children = [
      {Jobber.Job, args}
    ]

    options = [
      strategy: :one_for_one,
      max_seconds: 30
    ]

    Supervisor.init(children, options)
  end
end
