Download and mount ISO

```
$USERNAME=
$PASSWORD=
$VERSION=1.1.8

wget --user $USERNAME --password $PASSWORD https://pro.spec.org/private/osg/benchmarks/cpu/cpu2017-$VERSION.iso

mount -t iso9660 -o ro,exec,loop cpu2017-$VERSION.iso /mnt
```

Install
```
./install.sh
```

Install devtoolset-9 or change the config file to the existing devtoolset version/location

```
yum install -y devtoolset-9
```

Test run to build - change the config file and match cores to copies

```
$CORES=

runcpu --config=oguz --copies=$CORES --noreportable --iterations=1 --size=test intrate 
```

Excluding some tests if they're failing to run

```
runcpu --config=oguz --copies=$CORES --noreportable --iterations=1  --size=test intrate ^502
```

Non-reportable full (ref) run

```
runcpu --config=oguz --copies=$CORES --noreportable intrate
```

