    // ===============================
    // 📬 Envío automático de correos al crear cita
    // ===============================

    const functions = require("firebase-functions");
    const admin = require("firebase-admin");
    const nodemailer = require("nodemailer");
    const { createEvent } = require("ics");

    admin.initializeApp();
    const db = admin.firestore();

    // --- Configuración SMTP ---
    // 👉 ejecuta esto antes del deploy (solo una vez en tu terminal):
    // firebase functions:config:set smtp.user="tu_correo@gmail.com" smtp.pass="TU_APP_PASSWORD" smtp.host="smtp.gmail.com" smtp.port=465

    const transporter = nodemailer.createTransport({
    host: functions.config().smtp.host,
    port: Number(functions.config().smtp.port || 465),
    secure: true,
    auth: {
        user: functions.config().smtp.user,
        pass: functions.config().smtp.pass,
    },
    });

    // --- Función principal ---
    exports.onCreateCitaSendMail = functions.firestore
    .document("citas/{citaId}")
    .onCreate(async (snap, ctx) => {
        const cita = snap.data();
        const negocioId = ctx.params.negocioId;

        try {
        // 🔹 Leer datos del negocio
        const negDoc = await db.collection("negocios").doc(negocioId).get();
        const negocio = negDoc.data() || {};
        const negocioNombre = negocio.businessName || "Tu Empresa";
        const ownerEmail = negocio.ownerEmail || functions.config().smtp.user;

        // 🔹 Fechas de la cita
        const start = cita.fechaInicio.toDate();
        const end = cita.fechaFin.toDate();

        // 🔹 Crear archivo .ics (evento de calendario)
        const { error, value } = createEvent({
            title: `${cita.servicioNombre} con ${cita.staffNombre} - ${negocioNombre}`,
            description: `Reserva en ${negocioNombre}\nCliente: ${cita.clienteNombre}\nProfesional: ${cita.staffNombre}`,
            start: [
            start.getFullYear(),
            start.getMonth() + 1,
            start.getDate(),
            start.getHours(),
            start.getMinutes(),
            ],
            end: [
            end.getFullYear(),
            end.getMonth() + 1,
            end.getDate(),
            end.getHours(),
            end.getMinutes(),
            ],
            location: negocio.address || "",
            status: "CONFIRMED",
            organizer: { name: negocioNombre, email: ownerEmail },
            alarms: [{ action: "display", trigger: { minutes: 30, before: true } }],
        });

        if (error) console.error("Error creando ICS:", error);

        const attachments = value
            ? [
                {
                filename: "cita.ics",
                content: value,
                contentType: "text/calendar",
                },
            ]
            : [];

        // 🔹 Correo al cliente
        const toClient = {
            from: `"${negocioNombre}" <${functions.config().smtp.user}>`,
            to: cita.clienteEmail,
            subject: `Tu cita en ${negocioNombre} está confirmada`,
            text: `Hola ${cita.clienteNombre},\nTu cita para ${cita.servicioNombre} con ${cita.staffNombre} fue agendada para el ${start.toLocaleString()}.`,
            attachments,
        };

        // 🔹 Copia al dueño del negocio
        const toOwner = {
            from: `"${negocioNombre}" <${functions.config().smtp.user}>`,
            to: ownerEmail,
            subject: `Nueva cita agendada - ${cita.servicioNombre}`,
            text: `Cliente: ${cita.clienteNombre} (${cita.clienteEmail})\nProfesional: ${cita.staffNombre}\nFecha: ${start.toLocaleString()}`,
            attachments,
        };

        // 🔹 Enviar correos
        await transporter.sendMail(toClient);
        await transporter.sendMail(toOwner);

        console.log("📧 Correos enviados correctamente.");
        } catch (err) {
        console.error("❌ Error enviando correos:", err);
        }
    });
