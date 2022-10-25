script to debug g3w-suite memory consumption under gunicorn


What does it do ?

It can create tracemalloc snaphots and compare them to find memory leaks
it can make an aggressive garbage collection, so one can have a more realistic view of the memory used by python
(python tends to not give back small objects freed memory back to the os )


How to set up:

  if you are trying to debug memory problems, you might want to start by swapping off (as the time of writing docker stats does not seem to take swap into account):

    sudo swapoff -a


  you might want to set G3WSUITE_GUNICORN_NUM_WORKERS=1 into your .env file




 in your docker-compose.yml file under g3w-suite --> volumes  add
    \- ./scripts:/scripts

  if you want to save your traces for later (optional)
    \- ./Snaphots:/Snaphots



edit scripts/docker-entrypoint.sh and change the last line to be:

    -b 0.0.0.0:8000 \
    --config /scripts/debugger/gunicorn_debugger.py

    IMPORTANT: Do not forget the backslash on -b 0.0.0.0:8000 \


How to use:


start your docker g3w-suite with

    docker compose up -d

in one terminal follow the logs

    docker logs --follow g3w-suite-docker-g3w-suite-1  (or whatever name your container has)


in another terminal:

use ab (apache benchmark) to send one of the following


do_collect_often     : tries to collect the 3rd gen of garbage at a threshold of 10   ---->  ab   http\://localhost:8080/do_collect_often

do_not_collect_often : disables the above    ---->  ab   http\://localhost:8080/do_not_collect_often

do_agressive_gc      : tries to collect the 3rd gen of garbage after every request   ---->  ab   http\://localhost:8080/do_agressive_gc

do_no_agressive_gc   : disables the above   ---->  ab   http\://localhost:8080/do_no_agressive_gc

do_collect           : does collect      ---->  ab   http\://localhost:8080/do_collect

do_first_snap       : remove the content of /Snapshots and create the first tracemalloc snaphot in /Snapshots    ---->  ab   http\://localhost:8080/do_first_snap

do_snap             : create successive snapshot    ---->  ab   http\://localhost:8080/do_snap

do_snap(SnapName)   : create successive snapshot with name   ---->  ab   http\://localhost:8080/do_snap\(SnapName\)

do_compare_all      : compare all the snapshots and try to find increasing memory between those   ---->  ab   http\://localhost:8080/do_compare_all



Monitor the output on the terminal where you follow the logs


to see the memory used by the process: do

    while [ true ];do ps u -p `ps -ax|grep gunico|grep -v grep|awk ' { print $1 }'|tail -n1` | awk '{sum=sum+$6}; END {print sum/1024}';done



