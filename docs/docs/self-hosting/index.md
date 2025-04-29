---
title: Self Hosting
description: Getting started self hosting Ente Photos and/or Ente Auth
---

# Self Hosting

The entire source code for Ente is open source, including the servers. This is
the same code we use for our own cloud service.

> [!TIP]
>
> To get some context, you might find our
> [blog post](https://ente.io/blog/open-sourcing-our-server/) announcing the
> open sourcing of our server useful.


## System Requirements 

The server has minimal resource requirements, running as a lightweight Go binary 
with no server-side ML. It performs well on small cloud instances, old laptops,
and even [low-end embedded devices](https://github.com/ente-io/ente/discussions/594) 
reported by community members. Virtually any reasonable hardware should be sufficient.

## Getting started

Execute the below one-liner command in your terminal to setup Ente on your system. 

```sh
sh -c "$(curl -fsSL https://raw.githubusercontent.com/ente-io/ente/main/server/quickstart.sh)"
```

The above `curl` command is a simple shell-script, which pulls the docker images, 
creates a directory `my-ente` in the current working directory and starts all the 
containers required to run Ente on your system.

![quickstart](/quickstart.png)

## Queries?

If you need any help or support, do not hesitate to drop your queries on our community
[discord channel](https://discord.gg/z2YVKkycX3) or create a 
[Github Discussion](https://github.com/ente-io/ente/discussions) where 100s of self-hosters help each other.