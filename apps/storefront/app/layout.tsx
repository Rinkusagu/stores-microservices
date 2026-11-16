import type { ReactNode } from "react";

export const metadata = {
  title: "Resilient Commerce",
};

export default function RootLayout({ children }: { children: ReactNode }) {
  return (
    <html lang="en">
      <body
        style={{
          fontFamily: "Georgia, serif",
          margin: "2rem auto",
          maxWidth: "42rem",
          color: "#1c1917",
        }}
      >
        {children}
      </body>
    </html>
  );
}
