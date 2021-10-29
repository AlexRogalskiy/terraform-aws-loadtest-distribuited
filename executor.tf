locals {
    auto_execute = var.auto_execute

    nodes_private_ips = (
        var.executor == "jmeter" ? 
            join(",",aws_instance.nodes.*.private_ip) : 
            "['${join("','",aws_instance.nodes.*.private_ip)}']"
    )

    leader_private_ip = aws_instance.leader.private_ip
}

resource "null_resource" "executor" {

    count = local.auto_execute ? 1 : 0

    depends_on = [
        aws_instance.leader,
        aws_instance.nodes
    ]  

    connection {
        host        = coalesce(aws_instance.leader.public_ip, aws_instance.leader.private_ip)
        type        = "ssh"
        user        = var.ssh_user
        private_key = tls_private_key.loadtest.private_key_pem
    }

    #EXECUTE SCRIPTS
    provisioner "remote-exec" {
        inline = [
            #"while [ ! -f /var/lib/apache-jmeter-5.3/bin/jmeter ]; do sleep 10; done",
            "echo 'START EXECUTION'",
            "echo DIR: ${var.loadtest_dir_destination}",
            "cd ${var.loadtest_dir_destination}",
            "echo JVM_ARGS: $JVM_ARGS",
            "echo ${replace(var.loadtest_entrypoint, "{NODES_IPS}", local.nodes_private_ips)}",
            replace(var.loadtest_entrypoint, "{NODES_IPS}", local.nodes_private_ips)
        ]
    }
    triggers = {
        always_run = timestamp()
    }

}
