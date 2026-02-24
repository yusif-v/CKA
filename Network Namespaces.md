# Network Namespaces
## Overview

A **Network Namespace** is a Linux feature that provides isolated network environments within a single host.

Each namespace has its own:
- Network interfaces
- IP addresses
- Routing table
- ARP table
- Firewall rules
- DNS configuration

This isolation allows multiple network stacks to exist independently on the same machine.

Network Namespace = _Virtual Network Stack Isolation_

## Why Network Namespaces Exist

In traditional systems:
1. All processes share the same network configuration.
2. Changing routes or interfaces affects the entire host.
3. Isolation between applications is difficult.

Network namespaces solve this by allowing each workload to have its **own independent networking environment**, which is essential for containerization.

## How Network Namespaces Work

Workflow:

```bash
Create Namespace → Attach Interfaces → Assign IP → Configure Routes → Run Processes Inside
```

Processes running inside a namespace only see the interfaces and routes assigned to that namespace.

They behave as if they are running on a completely separate machine.

## Creating a Network Namespace

Create a namespace:

```bash
ip netns add ns1
```

List namespaces:

```bash
ip netns list
```

Delete a namespace:

```bash
ip netns delete ns1
```

## Running Commands Inside a Namespace

Execute commands within the namespace:

```bash
ip netns exec ns1 ip addr
ip netns exec ns1 ping 8.8.8.8
```

This runs the command using that namespace’s isolated network stack.

## Connecting Namespaces Using veth Pair

Namespaces are connected using **virtual ethernet (veth) pairs**.

A veth pair acts like a virtual cable:
- One end stays in the root namespace
- The other moves into the new namespace

Create a veth pair:

```bash
ip link add veth-host type veth peer name veth-ns
```

Move one end into the namespace:

```bash
ip link set veth-ns netns ns1
```

## Assigning IP Addresses

Configure interfaces:

```bash
ip addr add 10.0.0.1/24 dev veth-host
ip link set veth-host up
```

Inside the namespace:

```bash
ip netns exec ns1 ip addr add 10.0.0.2/24 dev veth-ns
ip netns exec ns1 ip link set veth-ns up
ip netns exec ns1 ip link set lo up
```

Now both ends can communicate.

## Testing Connectivity

```bash
ip netns exec ns1 ping 10.0.0.1
```

If configured correctly, the namespace behaves like a separate host connected via a network cable.

## Network Namespace Isolation

Each namespace has its own:

|**Component**|**Isolated?**|
|---|---|
|Interfaces|Yes|
|Routing Table|Yes|
|Firewall Rules|Yes|
|Port Bindings|Yes|
|Loopback Device|Yes|

Processes in different namespaces cannot see each other’s network unless explicitly connected.

## Relationship to Containers

Containers use network namespaces to provide:
- Pod-level networking isolation
- Independent IP addresses
- Virtual interfaces
- Internal routing

Every container (or Pod) operates inside its own network namespace.

## Viewing Namespace Interfaces

Check interfaces inside a namespace:

```bash
ip netns exec ns1 ip link
```

View routing table:

```bash
ip netns exec ns1 ip route
```

## Important Behavior

Network namespaces do not provide connectivity by default.

They start completely isolated.
Connectivity must be explicitly built using:
- veth pairs
- Bridges
- Routing rules
- NAT configuration

This design gives full control over how communication is allowed.

## Summary

Network Namespaces provide low-level network isolation by giving each environment its own independent network stack, enabling container technologies and orchestration systems to create fully separated, software-defined networks on a single host.