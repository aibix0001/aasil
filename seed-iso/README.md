# hiermit die seed.iso für vyos ZTP erstellen

Zuerst user-data bearbeiten und die eigenen keys hinterlegen!


Mit folgendem Befehl die seed.iso erstellen:

mkisofs -joliet -rock -volid "cidata" -output seed.iso meta-data user-data network-config


Dann die seed.iso in /var/lib/vz/template/iso ablegen.

Man kann auch alternativ die iso direkt dort ablegen, dann muss man aber mkisofs als root ausführen:

sudo mkisofs -joliet -rock -volid "cidata" -output /var/lib/vz/template/iso/seed.iso meta-data user-data network-config
