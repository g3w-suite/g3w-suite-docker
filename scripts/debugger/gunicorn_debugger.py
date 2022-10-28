import multiprocessing
import gc
import time
import tracemalloc
import os
import glob
import re
import numpy
import sys

do_collect_often = False
do_aggressive_collection = False
snapnumber = 1
os.makedirs("/Snaphots", exist_ok=True)

def post_request(worker, req, environ, resp):
    global do_collect_often
    global do_aggressive_collection
    global snapnumber

    if "do_collect_often" in str(environ):
        do_collect_often = True

    if "do_not_collect_often" in str(environ):
        do_collect_often = False

    if "do_aggressive_gc" in str(environ):
        do_aggressive_collection = True

    if "do_no_aggressive_gc" in str(environ):
        do_aggressive_collection = False


    if do_collect_often:
        ## To get a more realistic view of the memory in docker stats, we clean up the 3rd gen of gc collector more often
        Count = gc.get_count()
        SecondGenCount = Count[2]
        if (SecondGenCount > 1):
            gc.collect(2)
            worker.log.info("---------------------------gc collected---------------------------------")

    if do_aggressive_collection:
        gc.collect()
        gc.collect(2)

    if "do_first_snap" in str(environ):
        tracemalloc.start()
        worker.log.info("creating first snapshot")
        files = glob.glob('/Snaphots/*')
        for f in files:
            os.remove(f)

        gc.collect()
        gc.collect(2)
        firstsnap = tracemalloc.take_snapshot()
        firstsnap.dump("/Snaphots/1_snap")
        del firstsnap
        snapnumber = 2

    if "do_snap" in str(environ):

        if snapnumber != 1:
            x = re.search("PATH_INFO\': \'/do_snap\((?P<newsnapname>..+)\)", str(environ))

            if x:

                print(x.group('newsnapname'))
                filename = str(snapnumber) + "___" + x.group('newsnapname')
                gc.collect()
                gc.collect(2)
                snapshot = tracemalloc.take_snapshot()
                snapshot.dump("/Snaphots/" + filename)
                del snapshot
                snapnumber += 1
            else:

                filename = str(snapnumber) + "___snap"
                gc.collect()
                snapshot = tracemalloc.take_snapshot()
                snapshot.dump("/Snaphots/" + filename)
                del snapshot
                snapnumber += 1

        else:
            worker.log.info(
                "\n\n\n                                         You must call do_first_snap before calling do_snap  \n\n\n")
    if "do_collect" in str(environ):
        gc.collect()
        worker.log.info("---------------------------collected---------------------------------")

    if "do_compare_all" in str(environ):

        all_files = []
        snaps = []
        worker.log.info("---------------------------comparing---------------------------------")
        files = glob.glob('/Snaphots/*')
        sorted_files = sorted(files, key=lambda x: float(re.findall("(\d+)", x)[0]))
        for f in sorted_files:
            worker.log.info("loading file " + str(f))
            snapshot = tracemalloc.Snapshot.load(f)
            snaps.append(snapshot)
            del snapshot
            all_files.append(f)
        first = snaps[0]
        i = 1
        for snapshot in snaps[1:]:
            stats = snapshot.compare_to(first, 'lineno')
            worker.log.info("\n\n************************** top 10 stats ***  " + str(all_files[i]) + "\n")
            i += 1
            for s in stats[:10]:
                worker.log.info(s)

        worker.log.info("\n\n**************************    trying to find incrementing memory \n")

        result_array = []

        result_array_mem_increase = []
        result_array_occurences = []
        for snapshot in snaps[1:]:
            stats = snapshot.compare_to(first, 'lineno')
            for s in stats[:10]:
                sp = str(s).split(" ")

                x = re.search("\((?P<memory>..+)", str(sp[3]))
                if x:
                    mem = float(x.group('memory'))

                x = re.search("KiB", str(sp[4]))
                if x:
                    mem = mem * 1024

                if not sp[0] in result_array:
                    result_array.append(sp[0])
                    result_array_mem_increase.append(mem)
                    result_array_occurences.append(1)
                else:
                    ind = result_array.index(sp[0])

                    if (mem > result_array_mem_increase[ind]):
                        result_array_mem_increase[ind] = mem
                        result_array_occurences[ind] += 1

                np_arr = numpy.array(result_array_mem_increase)
                sorted_indexes = np_arr.astype(numpy.float).argsort()

        found_something = 0
        for i in sorted_indexes:
            if int(result_array_mem_increase[i]) > 0:
                found_something=1
                worker.log.info(
                    str(result_array[i]) + " increased by  " + str(
                        result_array_mem_increase[i]) + " Bytes and increased " + str(
                        result_array_occurences[i]) + " times")
        if found_something == 0:
            worker.log.info("did not find any memory increase")
        del snaps
