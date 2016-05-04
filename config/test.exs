use Mix.Config

config :assembly_line, check_interval: 100
config :assembly_line, job_executor: AssemblyLine.JobQueue.HandlerTest.CustomWorker
