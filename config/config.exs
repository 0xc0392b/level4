import Config

config :level4, Storage.Repo,
  database: "level4",
  username: "level4",
  password: "level4",
  hostname: "127.0.0.1",
  port: 5432

config :level4, ecto_repos: [Storage.Repo]