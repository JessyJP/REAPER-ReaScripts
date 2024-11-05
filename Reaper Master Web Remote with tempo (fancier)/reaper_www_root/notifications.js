// Function to display a notification message with optional position, font size, and display duration parameters
function notificationMessage(messageText, top = '10%', left = '50%', fontSize = '1.2em', displayDuration = 3000/*duration in milliseconds*/) {
    // Check if the alert div already exists; if not, create it
    let notification = document.getElementById('notificationMessageOverlay');
    if (!notification) {
        notification = document.createElement('div');
        notification.id = 'notificationMessageOverlay';
        document.body.appendChild(notification);

        // Apply CSS styles directly in JavaScript
        notification.style.position = 'fixed';
        notification.style.backgroundColor = 'rgba(0, 0, 0, 0.7)';
        notification.style.color = 'white';
        notification.style.padding = '1em';
        notification.style.borderRadius = '5px';
        notification.style.zIndex = '1000';
        notification.style.display = 'none'; // Initially hidden
    }

    // Set position and font size with optional parameters
    notification.style.top = top;
    notification.style.left = left;
    notification.style.fontSize = fontSize;
    notification.style.transform = 'translateX(-50%)'; // Centers the message horizontally

    // Update the message content and show the alert
    notification.textContent = messageText;
    notification.style.display = 'block';

    // Clear any existing timeout to reset the timer
    if (notification.hideTimeout) {
        clearTimeout(notification.hideTimeout);
    }

    // Hide the notification after the specified display duration
    notification.hideTimeout = setTimeout(() => {
        notification.style.display = 'none';
    }, displayDuration);
}
// Example usage: Display a message with custom position, font size, and display duration
// notificationMessage("Custom positioned notification", "20%", "40%", "1.5em", 5000);