/**
 * AWS Lambda function for processing contact form submissions
 * Sends emails via AWS SES
 */

const {SESClient, SendEmailCommand} = require('@aws-sdk/client-ses');
const ses = new SESClient({region: 'us-east-1'});

// HTML escaping function to prevent XSS
function escapeHtml(text) {
  if (typeof text !== 'string') {
    return '';
  }

  return text
    .replace(/&/g, '&amp;')
    .replace(/</g, '&lt;')
    .replace(/>/g, '&gt;')
    .replace(/"/g, '&quot;')
    .replace(/'/g, '&#039;');
}

exports.handler = async(event) => {
  // Enable CORS
  const headers = {
    'Access-Control-Allow-Origin': '*',
    'Access-Control-Allow-Headers': 'Content-Type',
    'Access-Control-Allow-Methods': 'POST, OPTIONS',
    'Content-Type': 'application/json'
  };

  // Handle preflight OPTIONS request
  if (event.httpMethod === 'OPTIONS') {
    return {
      statusCode: 200,
      headers,
      body: JSON.stringify({message: 'CORS preflight'})
    };
  }

  try {
    // Parse the request body
    const body = JSON.parse(event.body);
    const {name, email, subject, message} = body;

    // Validate required fields
    if (!name || !email || !subject || !message) {
      return {
        statusCode: 400,
        headers,
        body: JSON.stringify({
          error: 'Missing required fields',
          required: ['name', 'email', 'subject', 'message']
        })
      };
    }

    // Validate email format
    const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
    if (!emailRegex.test(email)) {
      return {
        statusCode: 400,
        headers,
        body: JSON.stringify({error: 'Invalid email format'})
      };
    }

    // Create email content
    const emailParams = {
      Source: 'info@robertconsulting.net',
      Destination: {
        ToAddresses: ['info@robertconsulting.net']
      },
      Message: {
        Subject: {
          Data: `Contact Form: ${subject}`,
          Charset: 'UTF-8'
        },
        Body: {
          Html: {
            Data: `
                            <html>
                                <body>
                                    <h2>New Contact Form Submission</h2>
                                    <p><strong>Name:</strong> ${escapeHtml(name)}</p>
                                    <p><strong>Email:</strong> ${escapeHtml(email)}</p>
                                    <p><strong>Subject:</strong> ${escapeHtml(subject)}</p>
                                    <p><strong>Message:</strong></p>
                                    <p>${escapeHtml(message).replace(/\n/g, '<br>')}</p>
                                    <hr>
                                    <p><em>Sent from robertconsulting.net contact form</em></p>
                                </body>
                            </html>
                        `,
            Charset: 'UTF-8'
          },
          Text: {
            Data: `
New Contact Form Submission

Name: ${name}
Email: ${email}
Subject: ${subject}

Message:
${message}

---
Sent from robertconsulting.net contact form
                        `,
            Charset: 'UTF-8'
          }
        }
      }
    };

    // Send email via SES
    const command = new SendEmailCommand(emailParams);
    const result = await ses.send(command);

    // Log successful submission
    console.log('Email sent successfully:', result.MessageId);

    return {
      statusCode: 200,
      headers,
      body: JSON.stringify({
        message: 'Email sent successfully',
        messageId: result.MessageId
      })
    };

  } catch (error) {
    console.error('Error sending email:', error);

    return {
      statusCode: 500,
      headers,
      body: JSON.stringify({
        error: 'Failed to send email',
        details: error.message
      })
    };
  }
};
