use Mix.Config

config :assembly_line, job_executor: AssemblyLine.TestWorker
config :assembly_line, check_interval: 100
