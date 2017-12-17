#!/bin/bash

QEMU=${QEMU:-~/qemu-system-aarch64}
CONSOLE=mon:stdio
SMP=4
MEMSIZE=$((14 * 1024))
KERNEL=Image
declare -a INCOMING
FS=arm64-trusty.img
CMDLINE=""
DUMPDTB=""
KERNEL_IRQCHIP="on"
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
	U="$U    -k | --kernel <Image>: Use kernel image (default ${KERNEL})\n"
	U="$U    -s | --serial <file>:  Output console to <file>\n"
	U="$U    -i | --image <image>:  Use <image> as block device (default $FS)\n"
	U="$U    -a | --append <snip>:  Add <snip> to the kernel cmdline\n"
	U="$U    --userirq:             Don't use an in-kernel GIC\n"
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
	  -k | --kernel)
		KERNEL="$2"
		shift 2
		;;
	  -s | --serial)
		CONSOLE="file:$2"
		shift 2
		;;
	  -i | --image)
		FS="$2"
		shift 2
		;;
	  -a | --append)
		CMDLINE="$2"
		shift 2
		;;
	  --userirq)
		KERNEL_IRQCHIP="off"
		shift 1
		;;
	  --incoming)
		INCOMING=(-incoming "exec: gzip -c -d $2")
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
		ALTCON="-chardev socket,server,host=*,nowait,port=$PORT,telnet,id=mychardev,logfile=/tmp/foo.txt"
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

        #-netdev bridge,id=net0 \

$QEMU \
        -smp $SMP -m $MEMSIZE -machine virt${DUMPDTB},kernel_irqchip=$KERNEL_IRQCHIP -cpu host \
        -kernel ${KERNEL} -enable-kvm ${DTB} \
        -drive if=none,file=$FS,id=vda,format=raw,cache=none \
        -device virtio-blk-pci,drive=vda \
	-netdev tap,id=net0,helper=/usr/local/bin/qemu-bridge-helper,vhost=on \
        -device virtio-net-pci,netdev=net0 \
	$QMP \
	"${INCOMING[@]}" \
        -display none \
	-serial $CONSOLE \
	$ALTCON \
	-append "console=ttyAMA0 root=/dev/vda rw $CMDLINE earlycon"

	#-incoming "exec: gzip -c -d STATEFILE.gz" \

        #-netdev bridge,id=net0 \

	#-chardev stdio,id=mychardev \
	#-device virtio-serial-device \
	#-device virtconsole,chardev=mychardev \

	#-chardev stdio,id=mychardev \
	#-chardev file,path=/tmp/serial2,id=file2 \
