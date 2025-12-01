const { Document, Packer, Paragraph, TextRun, Table, TableRow, TableCell, Header, Footer,
        AlignmentType, LevelFormat, HeadingLevel, BorderStyle, WidthType, ShadingType, 
        PageNumber, PageBreak } = require('docx');
const fs = require('fs');

const tableBorder = { style: BorderStyle.SINGLE, size: 1, color: "CCCCCC" };
const cellBorders = { top: tableBorder, bottom: tableBorder, left: tableBorder, right: tableBorder };
const headerShade = { fill: "1F4E79", type: ShadingType.CLEAR };

const doc = new Document({
  styles: {
    default: { document: { run: { font: "Arial", size: 24 } } },
    paragraphStyles: [
      { id: "Title", name: "Title", basedOn: "Normal",
        run: { size: 52, bold: true, font: "Arial" },
        paragraph: { spacing: { after: 200 }, alignment: AlignmentType.CENTER } },
      { id: "Heading1", name: "Heading 1", basedOn: "Normal", next: "Normal", quickFormat: true,
        run: { size: 32, bold: true, color: "1F4E79", font: "Arial" },
        paragraph: { spacing: { before: 360, after: 180 }, outlineLevel: 0 } },
      { id: "Heading2", name: "Heading 2", basedOn: "Normal", next: "Normal", quickFormat: true,
        run: { size: 26, bold: true, color: "2E75B6", font: "Arial" },
        paragraph: { spacing: { before: 240, after: 120 }, outlineLevel: 1 } }
    ]
  },
  numbering: {
    config: [
      { reference: "bullets", levels: [{ level: 0, format: LevelFormat.BULLET, text: "•", 
        alignment: AlignmentType.LEFT, style: { paragraph: { indent: { left: 720, hanging: 360 } } } }] },
      { reference: "num1", levels: [{ level: 0, format: LevelFormat.DECIMAL, text: "%1.",
        alignment: AlignmentType.LEFT, style: { paragraph: { indent: { left: 720, hanging: 360 } } } }] },
      { reference: "num2", levels: [{ level: 0, format: LevelFormat.DECIMAL, text: "%1.",
        alignment: AlignmentType.LEFT, style: { paragraph: { indent: { left: 720, hanging: 360 } } } }] }
    ]
  },
  sections: [{
    properties: { page: { margin: { top: 1440, right: 1440, bottom: 1440, left: 1440 } } },
    headers: { default: new Header({ children: [new Paragraph({ alignment: AlignmentType.RIGHT,
      children: [new TextRun({ text: "ECE 528 - Smart Door System", italics: true, size: 20, color: "666666" })] })] }) },
    footers: { default: new Footer({ children: [new Paragraph({ alignment: AlignmentType.CENTER,
      children: [new TextRun({ size: 20, children: ["Page "] }), new TextRun({ size: 20, children: [PageNumber.CURRENT] }),
        new TextRun({ size: 20, children: [" of "] }), new TextRun({ size: 20, children: [PageNumber.TOTAL_PAGES] })] })] }) },
    children: [
      // Title Page
      new Paragraph({ spacing: { before: 1800 }, children: [] }),
      new Paragraph({ heading: HeadingLevel.TITLE, children: [new TextRun("ECE 528: Cloud Computing")] }),
      new Paragraph({ alignment: AlignmentType.CENTER, spacing: { after: 100 },
        children: [new TextRun({ text: "University of Michigan-Dearborn", size: 28, bold: true })] }),
      new Paragraph({ spacing: { before: 500 }, children: [] }),
      new Paragraph({ alignment: AlignmentType.CENTER, children: [new TextRun({ text: "Project Report", size: 36, bold: true })] }),
      new Paragraph({ alignment: AlignmentType.CENTER, spacing: { before: 200, after: 400 },
        children: [new TextRun({ text: "Smart Door Authentication System", size: 32, bold: true, color: "1F4E79" })] }),
      new Paragraph({ spacing: { before: 800 }, children: [] }),
      new Paragraph({ alignment: AlignmentType.CENTER, children: [new TextRun("Prepared by:")] }),
      new Paragraph({ alignment: AlignmentType.CENTER, spacing: { before: 100 },
        children: [new TextRun({ text: "Joel", size: 28, bold: true })] }),
      new Paragraph({ spacing: { before: 500 }, children: [] }),
      new Paragraph({ alignment: AlignmentType.CENTER, children: [new TextRun("Fall 2025")] }),
      new Paragraph({ children: [new PageBreak()] }),

      // 1. Introduction
      new Paragraph({ heading: HeadingLevel.HEADING_1, children: [new TextRun("1. Introduction")] }),
      new Paragraph({ spacing: { after: 180 }, children: [new TextRun(
        "This project implements a Smart Door Authentication System using Amazon Web Services (AWS) cloud infrastructure. The system provides secure, automated access control through facial recognition technology to identify visitors and manage door access."
      )] }),
      new Paragraph({ spacing: { after: 180 }, children: [new TextRun(
        "The core objective is creating a distributed system that authenticates people in real-time using video stream analysis. It addresses the challenge of providing convenient access for known visitors while securing against unauthorized entry."
      )] }),
      new Paragraph({ heading: HeadingLevel.HEADING_2, children: [new TextRun("1.1 System Goals")] }),
      new Paragraph({ numbering: { reference: "bullets", level: 0 }, children: [new TextRun("Real-time visitor identification using Amazon Rekognition facial recognition")] }),
      new Paragraph({ numbering: { reference: "bullets", level: 0 }, children: [new TextRun("Automated OTP-based access for known visitors")] }),
      new Paragraph({ numbering: { reference: "bullets", level: 0 }, children: [new TextRun("Owner authorization workflow for unknown visitors")] }),
      new Paragraph({ numbering: { reference: "bullets", level: 0 }, children: [new TextRun("Secure virtual door with time-limited (5-minute TTL) access codes")] }),
      new Paragraph({ numbering: { reference: "bullets", level: 0 }, children: [new TextRun("Scalable serverless architecture")] }),
      new Paragraph({ children: [new PageBreak()] }),

      // 2. System Architecture
      new Paragraph({ heading: HeadingLevel.HEADING_1, children: [new TextRun("2. System Architecture")] }),
      new Paragraph({ spacing: { after: 180 }, children: [new TextRun(
        "The Smart Door Authentication System follows a serverless, event-driven architecture maximizing scalability while minimizing operational overhead. It consists of three main workflows: known visitor authentication, unknown visitor registration, and OTP validation."
      )] }),
      new Paragraph({ heading: HeadingLevel.HEADING_2, children: [new TextRun("2.1 AWS Components")] }),
      createComponentTable(),
      new Paragraph({ spacing: { before: 250 }, heading: HeadingLevel.HEADING_2, children: [new TextRun("2.2 Data Flow - Known Visitor")] }),
      new Paragraph({ numbering: { reference: "num1", level: 0 }, children: [new TextRun("Camera streams to Kinesis Video Stream (KVS1)")] }),
      new Paragraph({ numbering: { reference: "num1", level: 0 }, children: [new TextRun("Amazon Rekognition Video analyzes stream, detects faces")] }),
      new Paragraph({ numbering: { reference: "num1", level: 0 }, children: [new TextRun("Face match found in collection; event sent to Kinesis Data Stream (KDS1)")] }),
      new Paragraph({ numbering: { reference: "num1", level: 0 }, children: [new TextRun("Lambda LF1 triggered; looks up visitor in DynamoDB (DB2)")] }),
      new Paragraph({ numbering: { reference: "num1", level: 0 }, children: [new TextRun("OTP generated, stored in DB1 with 5-minute TTL")] }),
      new Paragraph({ numbering: { reference: "num1", level: 0 }, children: [new TextRun("SMS sent to visitor via Amazon SNS")] }),
      new Paragraph({ numbering: { reference: "num1", level: 0 }, children: [new TextRun("Visitor enters OTP on virtual door (WP2); access granted if valid")] }),
      new Paragraph({ heading: HeadingLevel.HEADING_2, children: [new TextRun("2.3 Data Flow - Unknown Visitor")] }),
      new Paragraph({ numbering: { reference: "num2", level: 0 }, children: [new TextRun("Unknown face detected (no match in collection)")] }),
      new Paragraph({ numbering: { reference: "num2", level: 0 }, children: [new TextRun("Lambda extracts frame, saves photo to S3 (B1)")] }),
      new Paragraph({ numbering: { reference: "num2", level: 0 }, children: [new TextRun("Owner receives SMS notification with photo and approval link")] }),
      new Paragraph({ numbering: { reference: "num2", level: 0 }, children: [new TextRun("Owner clicks link, opens registration page (WP1)")] }),
      new Paragraph({ numbering: { reference: "num2", level: 0 }, children: [new TextRun("Owner enters visitor name and phone number")] }),
      new Paragraph({ numbering: { reference: "num2", level: 0 }, children: [new TextRun("Face indexed in Rekognition; visitor record created")] }),
      new Paragraph({ numbering: { reference: "num2", level: 0 }, children: [new TextRun("OTP sent to visitor; access now possible")] }),
      new Paragraph({ children: [new PageBreak()] }),

      // 3. Implementation Details
      new Paragraph({ heading: HeadingLevel.HEADING_1, children: [new TextRun("3. Implementation Details")] }),
      new Paragraph({ heading: HeadingLevel.HEADING_2, children: [new TextRun("3.1 Data Storage")] }),
      new Paragraph({ spacing: { after: 100 }, children: [new TextRun({ text: "S3 Bucket (B1): ", bold: true }), new TextRun("Stores visitor photos with prefixes 'known/' and 'unknown/'. CORS configured for web access.")] }),
      new Paragraph({ spacing: { after: 100 }, children: [new TextRun({ text: "DynamoDB DB1 (Passcodes): ", bold: true }), new TextRun("Schema: otp (PK), faceId, visitorName, createdAt, ttl. TTL enables automatic 5-minute expiration.")] }),
      new Paragraph({ spacing: { after: 180 }, children: [new TextRun({ text: "DynamoDB DB2 (Visitors): ", bold: true }), new TextRun("Schema: faceId (PK), name, phoneNumber, photos[], createdAt.")] }),
      new Paragraph({ heading: HeadingLevel.HEADING_2, children: [new TextRun("3.2 Video Processing")] }),
      new Paragraph({ spacing: { after: 180 }, children: [new TextRun(
        "Video is captured and streamed to Kinesis Video Streams using the KVS Producer SDK with GStreamer. A Rekognition Stream Processor subscribes to the stream, performing continuous face search with 80% confidence threshold. Detection events output to Kinesis Data Stream, triggering Lambda processing."
      )] }),
      new Paragraph({ heading: HeadingLevel.HEADING_2, children: [new TextRun("3.3 Web Interfaces")] }),
      new Paragraph({ spacing: { after: 100 }, children: [new TextRun({ text: "WP1 (Registration): ", bold: true }), new TextRun("Displays captured photo; form for visitor name/phone. Calls /register API to index face and create record.")] }),
      new Paragraph({ spacing: { after: 180 }, children: [new TextRun({ text: "WP2 (Virtual Door): ", bold: true }), new TextRun("6-digit OTP input interface. Calls /validate API; displays access granted/denied result.")] }),
      new Paragraph({ children: [new PageBreak()] }),

      // 4. Lambda Functions
      new Paragraph({ heading: HeadingLevel.HEADING_1, children: [new TextRun("4. APIs and Lambda Functions")] }),
      new Paragraph({ heading: HeadingLevel.HEADING_2, children: [new TextRun("4.1 LF1 - Process Rekognition Events")] }),
      new Paragraph({ spacing: { after: 180 }, children: [new TextRun(
        "Triggered by Kinesis Data Stream. Decodes event payload, extracts FaceSearchResponse. For matched faces: looks up visitor, generates OTP, sends SMS. For unknown faces: saves photo to S3, notifies owner with approval link."
      )] }),
      new Paragraph({ heading: HeadingLevel.HEADING_2, children: [new TextRun("4.2 LF2 - Visitor Registration API")] }),
      new Paragraph({ spacing: { after: 100 }, children: [new TextRun({ text: "Endpoint: ", bold: true }), new TextRun("POST /register")] }),
      new Paragraph({ spacing: { after: 100 }, children: [new TextRun({ text: "Request: ", bold: true }), new TextRun("{ name, phoneNumber, faceId, photoKey }")] }),
      new Paragraph({ spacing: { after: 180 }, children: [new TextRun({ text: "Response: ", bold: true }), new TextRun("{ message, visitorName, faceId }")] }),
      new Paragraph({ heading: HeadingLevel.HEADING_2, children: [new TextRun("4.3 LF3 - OTP Validation API")] }),
      new Paragraph({ spacing: { after: 100 }, children: [new TextRun({ text: "Endpoint: ", bold: true }), new TextRun("POST /validate")] }),
      new Paragraph({ spacing: { after: 100 }, children: [new TextRun({ text: "Request: ", bold: true }), new TextRun("{ otp }")] }),
      new Paragraph({ spacing: { after: 180 }, children: [new TextRun({ text: "Response: ", bold: true }), new TextRun("{ valid: true/false, message, visitorName }")] }),
      new Paragraph({ children: [new PageBreak()] }),

      // 5. Results and Testing
      new Paragraph({ heading: HeadingLevel.HEADING_1, children: [new TextRun("5. Results and Testing")] }),
      new Paragraph({ heading: HeadingLevel.HEADING_2, children: [new TextRun("5.1 Test Scenarios")] }),
      createTestTable(),
      new Paragraph({ spacing: { before: 250 }, heading: HeadingLevel.HEADING_2, children: [new TextRun("5.2 Performance Metrics")] }),
      new Paragraph({ numbering: { reference: "bullets", level: 0 }, children: [new TextRun({ text: "Face Detection Latency: ", bold: true }), new TextRun("2-3 seconds average")] }),
      new Paragraph({ numbering: { reference: "bullets", level: 0 }, children: [new TextRun({ text: "OTP Delivery: ", bold: true }), new TextRun("SMS received within 5-10 seconds")] }),
      new Paragraph({ numbering: { reference: "bullets", level: 0 }, children: [new TextRun({ text: "Recognition Accuracy: ", bold: true }), new TextRun("80% threshold yields high accuracy")] }),
      new Paragraph({ numbering: { reference: "bullets", level: 0 }, children: [new TextRun({ text: "API Response: ", bold: true }), new TextRun("Under 500ms for registration and validation")] }),
      new Paragraph({ children: [new PageBreak()] }),

      // 6. Discussion
      new Paragraph({ heading: HeadingLevel.HEADING_1, children: [new TextRun("6. Discussion")] }),
      new Paragraph({ heading: HeadingLevel.HEADING_2, children: [new TextRun("6.1 Challenges")] }),
      new Paragraph({ spacing: { after: 100 }, children: [new TextRun({ text: "Video Frame Extraction: ", bold: true }), new TextRun("Required GetMedia API and MKV parsing. Solved using AWS SDK media endpoint.")] }),
      new Paragraph({ spacing: { after: 100 }, children: [new TextRun({ text: "Stream Processor Setup: ", bold: true }), new TextRun("Required dedicated IAM role with Kinesis permissions for Rekognition.")] }),
      new Paragraph({ spacing: { after: 180 }, children: [new TextRun({ text: "SMS Delivery: ", bold: true }), new TextRun("SNS sandbox limits to verified numbers. Production requires spending limit increase.")] }),
      new Paragraph({ heading: HeadingLevel.HEADING_2, children: [new TextRun("6.2 Scalability")] }),
      new Paragraph({ spacing: { after: 180 }, children: [new TextRun(
        "Serverless architecture provides automatic scaling. Lambda scales with events, DynamoDB uses on-demand capacity, Kinesis streams can add shards. System handles multiple concurrent visitors without modification."
      )] }),
      new Paragraph({ heading: HeadingLevel.HEADING_2, children: [new TextRun("6.3 Security")] }),
      new Paragraph({ numbering: { reference: "bullets", level: 0 }, children: [new TextRun("OTPs expire after 5 minutes via DynamoDB TTL")] }),
      new Paragraph({ numbering: { reference: "bullets", level: 0 }, children: [new TextRun("One-time use: OTPs deleted after successful validation")] }),
      new Paragraph({ numbering: { reference: "bullets", level: 0 }, children: [new TextRun("IAM roles follow least-privilege principle")] }),
      new Paragraph({ numbering: { reference: "bullets", level: 0 }, children: [new TextRun("80% face match threshold prevents false positives")] }),
      new Paragraph({ children: [new PageBreak()] }),

      // 7. Conclusion
      new Paragraph({ heading: HeadingLevel.HEADING_1, children: [new TextRun("7. Conclusion")] }),
      new Paragraph({ spacing: { after: 180 }, children: [new TextRun(
        "The Smart Door Authentication System successfully demonstrates AWS service integration for an intelligent, secure access control solution. It achieves real-time visitor identification, automated OTP access for known visitors, and streamlined authorization for unknown visitors."
      )] }),
      new Paragraph({ spacing: { after: 180 }, children: [new TextRun(
        "Key achievements include sub-3-second face detection, reliable SMS delivery, and user-friendly web interfaces. The serverless architecture ensures scalability and cost efficiency while maintaining security through time-limited, single-use access codes."
      )] }),
      new Paragraph({ heading: HeadingLevel.HEADING_2, children: [new TextRun("7.1 Future Enhancements")] }),
      new Paragraph({ numbering: { reference: "bullets", level: 0 }, children: [new TextRun("Multi-factor authentication combining face recognition with PIN")] }),
      new Paragraph({ numbering: { reference: "bullets", level: 0 }, children: [new TextRun("Visitor access scheduling and time-based restrictions")] }),
      new Paragraph({ numbering: { reference: "bullets", level: 0 }, children: [new TextRun("Access logging and analytics dashboard")] }),
      new Paragraph({ numbering: { reference: "bullets", level: 0 }, children: [new TextRun("Integration with physical door locks via IoT")] }),
      new Paragraph({ children: [new PageBreak()] }),

      // 8. References
      new Paragraph({ heading: HeadingLevel.HEADING_1, children: [new TextRun("8. References")] }),
      new Paragraph({ numbering: { reference: "bullets", level: 0 }, children: [new TextRun("Amazon Rekognition Developer Guide - https://docs.aws.amazon.com/rekognition/")] }),
      new Paragraph({ numbering: { reference: "bullets", level: 0 }, children: [new TextRun("Amazon Kinesis Video Streams Guide - https://docs.aws.amazon.com/kinesisvideostreams/")] }),
      new Paragraph({ numbering: { reference: "bullets", level: 0 }, children: [new TextRun("DynamoDB TTL Documentation - https://docs.aws.amazon.com/amazondynamodb/latest/developerguide/TTL.html")] }),
      new Paragraph({ numbering: { reference: "bullets", level: 0 }, children: [new TextRun("AWS Lambda Developer Guide - https://docs.aws.amazon.com/lambda/")] }),
      new Paragraph({ numbering: { reference: "bullets", level: 0 }, children: [new TextRun("Amazon SNS Developer Guide - https://docs.aws.amazon.com/sns/")] }),
      new Paragraph({ numbering: { reference: "bullets", level: 0 }, children: [new TextRun("KVS GStreamer Plugin - https://docs.aws.amazon.com/kinesisvideostreams/latest/dg/examples-gstreamer-plugin.html")] }),
    ]
  }]
});

function createComponentTable() {
  const rows = [
    ["S3 (B1)", "Visitor photo storage"],
    ["DynamoDB (DB1)", "Passcodes with 5-min TTL"],
    ["DynamoDB (DB2)", "Visitors indexed by FaceId"],
    ["Kinesis Video (KVS1)", "Video stream ingestion"],
    ["Kinesis Data (KDS1)", "Face detection events"],
    ["Rekognition Collection", "Indexed faces for matching"],
    ["Lambda LF1", "Process Rekognition events"],
    ["Lambda LF2", "Visitor registration API"],
    ["Lambda LF3", "OTP validation API"],
    ["API Gateway", "REST API endpoints"],
    ["SNS", "SMS notifications"]
  ];
  return new Table({
    columnWidths: [2800, 6560],
    rows: [
      new TableRow({ tableHeader: true, children: [
        new TableCell({ borders: cellBorders, shading: headerShade, children: [new Paragraph({ alignment: AlignmentType.CENTER, children: [new TextRun({ text: "Component", bold: true, color: "FFFFFF" })] })] }),
        new TableCell({ borders: cellBorders, shading: headerShade, children: [new Paragraph({ alignment: AlignmentType.CENTER, children: [new TextRun({ text: "Purpose", bold: true, color: "FFFFFF" })] })] })
      ]}),
      ...rows.map(([c, p]) => new TableRow({ children: [
        new TableCell({ borders: cellBorders, children: [new Paragraph({ children: [new TextRun({ text: c, bold: true })] })] }),
        new TableCell({ borders: cellBorders, children: [new Paragraph({ children: [new TextRun(p)] })] })
      ]}))
    ]
  });
}

function createTestTable() {
  const tests = [
    ["Known Visitor", "Registered face", "OTP sent", "Pass"],
    ["Unknown Visitor", "New face", "Owner notified", "Pass"],
    ["Registration", "Form submit", "Record created", "Pass"],
    ["Valid OTP", "Correct code", "Access granted", "Pass"],
    ["Invalid OTP", "Wrong code", "Access denied", "Pass"],
    ["Expired OTP", "Old code", "Access denied", "Pass"]
  ];
  return new Table({
    columnWidths: [2340, 2340, 2340, 1340],
    rows: [
      new TableRow({ tableHeader: true, children: [
        new TableCell({ borders: cellBorders, shading: headerShade, children: [new Paragraph({ alignment: AlignmentType.CENTER, children: [new TextRun({ text: "Test", bold: true, color: "FFFFFF" })] })] }),
        new TableCell({ borders: cellBorders, shading: headerShade, children: [new Paragraph({ alignment: AlignmentType.CENTER, children: [new TextRun({ text: "Input", bold: true, color: "FFFFFF" })] })] }),
        new TableCell({ borders: cellBorders, shading: headerShade, children: [new Paragraph({ alignment: AlignmentType.CENTER, children: [new TextRun({ text: "Expected", bold: true, color: "FFFFFF" })] })] }),
        new TableCell({ borders: cellBorders, shading: headerShade, children: [new Paragraph({ alignment: AlignmentType.CENTER, children: [new TextRun({ text: "Result", bold: true, color: "FFFFFF" })] })] })
      ]}),
      ...tests.map(([t, i, e, r]) => new TableRow({ children: [
        new TableCell({ borders: cellBorders, children: [new Paragraph({ children: [new TextRun(t)] })] }),
        new TableCell({ borders: cellBorders, children: [new Paragraph({ children: [new TextRun(i)] })] }),
        new TableCell({ borders: cellBorders, children: [new Paragraph({ children: [new TextRun(e)] })] }),
        new TableCell({ borders: cellBorders, children: [new Paragraph({ alignment: AlignmentType.CENTER, children: [new TextRun({ text: r, bold: true, color: "28A745" })] })] })
      ]}))
    ]
  });
}

Packer.toBuffer(doc).then(buffer => {
  fs.writeFileSync("/mnt/user-data/outputs/Smart_Door_Project_Report.docx", buffer);
  console.log("Report created: Smart_Door_Project_Report.docx");
});
