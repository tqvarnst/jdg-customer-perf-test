jdg-customer-perf-test
======================

This project runs a performance test based on a use-case where one jdg library node is used to write to the cache and mulitple others read the info

To build

    sh cli.sh build
    
To start server (mpstat) log

    sh cli.sh start server-log

To start readers (N=int with number of readers)
 
    sh cli.sh start reader N
    
To start writer

    sh cli.sh start writer
    
