package main

import (
	"context"
	"fmt"
	"log"
	"regexp"
	"text/tabwriter"

	metav1 "k8s.io/apimachinery/pkg/apis/meta/v1"
	"k8s.io/client-go/kubernetes"
	"k8s.io/client-go/tools/clientcmd"
)

func main() {
	config, err := clientcmd.BuildConfigFromFlags("", clientcmd.RecommendedHomeFile)
	if err != nil {
		log.Fatalf("Failed to load kubeconfig: %v", err)
	}

	clientset, err := kubernetes.NewForConfig(config)
	if err != nil {
		log.Fatalf("Failed to create Kubernetes client: %v", err)
	}

	nodes, err := clientset.CoreV1().Nodes().List(context.TODO(), metav1.ListOptions{})
	if err != nil {
		log.Fatalf("Failed to list nodes: %v", err)
	}

	errorRegex := regexp.MustCompile(`^(Gpu|Rdma|Oca).*HasIssues$`)

	writer := tabwriter.NewWriter(
		log.Writer(), // output destination
		0,            // minwidth
		0,            // tabwidth
		3,            // padding
		' ',          // padchar
		0,            // flags
	)

	fmt.Fprintln(writer, "NAME\tOCID\tSERIAL\tERROR")

	for _, node := range nodes.Items {
		labels := node.Labels

		if labels["nvidia.com/gpu"] == "true" || labels["amd.com/gpu"] == "true" {
			name := node.Name
			ocid := node.Spec.ProviderID
			serial := labels["oci.oraclecloud.com/host.serial_number"]

			var errorMessage string
			for _, condition := range node.Status.Conditions {
				if errorRegex.MatchString(condition.Reason) {
					errorMessage = condition.Message
					break
				}
			}

			if errorMessage != "" {
				fmt.Fprintf(writer, "%s\t%s\t%s\t%s\n", name, ocid, serial, errorMessage)
			}
		}
	}

	writer.Flush()
}
