import { Card } from "@repo/ui/card";
import { sayHello } from "@repo/ui/hello";

export default function Page(): JSX.Element {
    sayHello();

    return (
        <main>
            <Card href={"http://example.org"}>Card</Card>
        </main>
    );
}
