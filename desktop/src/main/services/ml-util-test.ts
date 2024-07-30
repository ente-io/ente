console.log("in utility process");

process.parentPort.once("message", (e) => {
    console.log("got message in utility process", e);
    const [port] = e.ports;

    port?.on("message", (e2) => {
        console.log("got message on port in utility process", e2);
    });
});
