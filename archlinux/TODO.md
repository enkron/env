# invariant system

The idea is to run the docker image inside a kubernetes cluster, so the
underlying OS remains immutable.

1. Get list of the installed packages on the base system
2. Get list of the default packages in the container
