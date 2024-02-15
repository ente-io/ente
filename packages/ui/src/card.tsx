/** Test comment */
export function Card({
    href,
    children,
}: {
    href: string;
    children: React.ReactNode;
}): JSX.Element {
    return (
        <a href={href} rel="noopener noreferrer" target="_blank">
            <p>{children}</p>
        </a>
    );
}
