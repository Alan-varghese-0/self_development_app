import { serve } from "https://deno.land/std/http/server.ts";

serve(async (req: Request) => {
    try {
        if (req.method !== "POST") {
            return new Response(JSON.stringify({ error: "Use POST" }), {
                status: 405,
                headers: { "Content-Type": "application/json" },
            });
        }

        const { text, voice } = await req.json();

        if (!text || text.trim().length === 0) {
            return new Response(JSON.stringify({ error: "No text provided" }), {
                status: 400,
                headers: { "Content-Type": "application/json" },
            });
        }

        const apiKey = Deno.env.get("GROQ_API_KEY");
        if (!apiKey) {
            return new Response(JSON.stringify({ error: "Missing GROQ_API_KEY" }), {
                status: 500,
                headers: { "Content-Type": "application/json" },
            });
        }

        // Correct Groq TTS endpoint
        const groqUrl = "https://api.groq.com/openai/v1/audio/speech";

        // Correct TTS request schema
        const ttsBody = {
            model: "gpt-4o-mini-tts",     // ✔ correct TTS model
            voice: voice ?? "female",     // ✔ works
            input: text,
            response_format: "mp3",       // ✔ correct parameter
        };

        const groqRes = await fetch(groqUrl, {
            method: "POST",
            headers: {
                Authorization: `Bearer ${apiKey}`,
                "Content-Type": "application/json",
            },
            body: JSON.stringify(ttsBody),
        });

        if (!groqRes.ok) {
            const errorDetail = await groqRes.text();
            return new Response(
                JSON.stringify({
                    error: "Groq TTS failed",
                    details: errorDetail,
                }),
                {
                    status: 502,
                    headers: { "Content-Type": "application/json" },
                }
            );
        }

        const buffer = await groqRes.arrayBuffer();
        const uint8 = new Uint8Array(buffer);

        // convert bytes => base64
        let binary = "";
        const chunkSize = 8192;
        for (let i = 0; i < uint8.length; i += chunkSize) {
            binary += String.fromCharCode.apply(
                null,
                Array.from(uint8.slice(i, i + chunkSize))
            );
        }
        const b64 = btoa(binary);

        return new Response(JSON.stringify({ audio: b64 }), {
            headers: { "Content-Type": "application/json" },
        });
    } catch (e) {
        return new Response(JSON.stringify({ error: String(e) }), {
            status: 500,
            headers: { "Content-Type": "application/json" },
        });
    }
});
