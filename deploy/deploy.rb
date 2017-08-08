# config valid only for current version of Capistrano
lock '3.8.2'

set :application, 'penny'
set :repo_url, 'git@github.com:blkbrds/penny.git'
set :branch, `git rev-parse --abbrev-ref HEAD`.chomp
set :deploy_to, "~/apps/#{fetch(:application)}"
set :linked_dirs, %w{Config/secrets}
set :keep_releases, 5

namespace :deploy do
    task :fetch do
        on roles(:app) do
            execute("cd #{fetch(:deploy_to)}/current && swift package fetch")
        end
    end

    task :build do
        on roles(:app) do
            execute("cd #{fetch(:deploy_to)}/current && swift build -c release")
        end
    end

    task :restart do
        on roles(:app) do
            sudo :supervisorctl, :restart, "#{fetch(:application)}"
        end
    end

    after :publishing, 'deploy:fetch'
    after :publishing, 'deploy:build'
    after :publishing, 'deploy:restart'
end
