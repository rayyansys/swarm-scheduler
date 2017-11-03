# swarm-scheduler

Many solutions out there explain how to run cron tasks using docker.
However, none of them does that in a distributed manner and make use
of the swarm mode orchestration.
With swarm-scheduler, you can do that with additional benefits.

Each time a task is run, it is scheduled on an arbitrary node.
Moreover, resource reservations and/or limitations can be applied on tasks
according to the needs. Tasks also run inside any container image, let it
be ruby, python, php, ...etc or even an application specific image.
No new syntax to learn, just use the [docker compose](https://docs.docker.com/compose/compose-file) file syntax.

Bonus: this scheduler comes with [scaltainer](https://github.com/hammady/scaltainer), an auto-scaler for docker swarm mode based on application metrics.
To use it, just define a minutely task that calls scaltainer with proper configuration.

Here are the steps required to achieve this:

### Get the scheduler image

The easiest way is to pull it directly from docker hub:

    docker pull rayyanqcri/swarm-scheduler

### Deploy the cron stack

First thing to do is to write a docker stack yaml file describing
your cron tasks as explained in the introduction.
An example file is located here with the name `cron-services-example.yml`.
You can include any configuration as long as you abide with the following
restrictions:

1. Set `entrypoint` to run the task command.
2. `replicas` should be set to 0, otherwise the task will run 
as soon as the service is deployed for the number of times you specified.
3. Set `restart_policy.condition` to `none`. If you set to `on-failure`,
the task will restart automatically on failure. If set to `any` (default),
it will continuously restart. Both cases are typically not needed in cron tasks.

Once ready, deploy your cron stack on the swarm cluster:

    docker stack deploy -c cron-stack-example.yml cron

### Deploy the crontab schedule

A standard crontab file is used to schedule the tasks.
The only requirement is to set the cron task command to launch the corresponding service.
For example if you defined a service called `service1` in the cron stack,
and you want to run it once every minute, your crontab file should look like:

    * * * * * root run-task cron_service1

Once ready, deploy your crontab file as a docker config:

    docker config create crontab crontab-example

### Deploy the scheduler

With everything in place, it is time to deploy the scheduler itself
and start the action:

    docker stack deploy -c scheduler-service.yml scheduler

### Watch the service logs

One of the benefits of running cron tasks as docker services is that
you can see the output of the tasks using docker logs. With our
example, and the service name is service1:

    docker service logs cron_service1

### Updating the crontab or the cron stack

If you need to modify your cron tasks defined in the cron stack above,
just remove the stack and add it again with the modified file:

    docker stack rm cron
    docker stack deploy -c modified-cron-stack.yml cron

If what you need is just to change the cron schedule, modify
the docker config and deploy it again. Note that this will cause 
any running task to restart automatically (TODO need to verify that).

    docker service update --config-rm crontab scheduler_manager && \
    docker config rm crontab && \
    docker config create crontab crontab-example && \
    docker service update --config-add crontab scheduler_manager

