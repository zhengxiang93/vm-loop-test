#!/bin/bash

CONSOLE=mon:stdio
SMP=16
MEMSIZE=$((4 * 1024))
KERNEL=Image
FS=debian-sid.qcow2
CMDLINE=""
DUMPDTB=""
DTB=""
QMP=""
ALTCON=""

usage() {
	U=""
	if [[ -n "$1" ]]; then
		U="${U}$1\n\n"
	fi
	U="${U}Usage: $0 [options]\n\n"
	U="${U}Options:\n"
	U="$U    -c | --CPU <nr>:       Number of cores (default ${SMP})\n"
	U="$U    -m | --mem <MB>:       Memory size (default ${MEMSIZE})\n"
	U="$U    --kernel <Image>:      Guest kernel image (default ${KERNEL})\n"
	U="$U    --fs <image>:          Guest file system (default $FS)\n"
	U="$U    -s | --serial <file>:  Output console to <file>\n"
	U="$U    -a | --append <snip>:  Add <snip> to the kernel cmdline\n"
	U="$U    --alt-console <port>:  Listen for virtio console on telnet <port>\n"
	U="$U    --qmp <path>           Listen for UNIX QMP socket on <path>\n"
	U="$U    --dumpdtb <file>       Dump the generated DTB to <file>\n"
	U="$U    --dtb <file>           Use the supplied DTB instead of the auto-generated one\n"
	U="$U    -h | --help:           Show this output\n"
	U="${U}\n"
	echo -e "$U" >&2
}

while :
do
	case "$1" in
	  -c | --cpu)
		SMP="$2"
		shift 2
		;;
	  -m | --mem)
		MEMSIZE="$2"
		shift 2
		;;
	  --kernel)
		KERNEL="$2"
		shift 2
		;;
	  -s | --serial)
		CONSOLE="file:$2"
		shift 2
		;;
	  --fs)
		FS="$2"
		shift 2
		;;
	  -a | --append)
		CMDLINE="$2"
		shift 2
		;;
	  --qmp)
		QMP="-qmp unix:$2,server,nowait"
		shift 2
		;;
	  --dumpdtb)
		DUMPDTB=",dumpdtb=$2"
		shift 2
		;;
	  --dtb)
		DTB="-dtb $2"
		shift 2
		;;
	  --alt-console)
		PORT="$2"
		ALTCON="-chardev socket,server,host=*,nowait,port=$PORT,telnet,id=mychardev"
		ALTCON="$ALTCON -device virtio-serial-device"
		ALTCON="$ALTCON -device virtconsole,chardev=mychardev"
		shift 2
		;;
	  -h | --help)
		usage ""
		exit 1
		;;
	  --) # End of all options
		shift
		break
		;;
	  -*) # Unknown option
		echo "Error: Unknown option: $1" >&2
		exit 1
		;;
	  *)
		break
		;;
	esac
done

./qemu-system-aarch64 \
        -smp $SMP -m $MEMSIZE -machine virt,gic-version=host${DUMPDTB} -cpu host \
        -kernel ${KERNEL} -enable-kvm ${DTB} \
        -drive if=none,file=$FS,id=vda,format=qcow2,cache=none \
        -device virtio-blk-pci,drive=vda \
	-netdev user,id=net0 \
        -device virtio-net-pci,netdev=net0 \
	$QMP \
        -display none \
	-serial $CONSOLE \
	$ALTCON \
	-append "console=ttyAMA0 root=/dev/vda1 rw $CMDLINE earlycon"

	#-chardev stdio,id=mychardev \
	#-device virtio-serial-device \
	#-device virtconsole,chardev=mychardev \

	#-chardev stdio,id=mychardev \
	#-chardev file,path=/tmp/serial2,id=file2 \
