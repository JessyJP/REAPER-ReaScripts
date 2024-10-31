// fullscreen.js

// Constants for SVG symbols to represent fullscreen states
const FULLSCREEN_ENTER_ICON = `
    <svg width="32" height="32" viewBox="0 0 24 24">
        <rect x="2" y="2" width="30" height="30" fill="#333333" />
        <text x="12" y="18" text-anchor="middle" fill="#FFFFFF" font-size="15px">⛶</text>
    </svg>
`;

const FULLSCREEN_EXIT_ICON = `
    <svg width="32" height="32" viewBox="0 0 24 24">
        <rect x="2" y="2" width="28" height="28" fill="#333333" />
        <text x="12" y="16" text-anchor="middle" fill="#FFFFFF" font-size="10px">⛶</text>
        <line x1="4" y1="4" x2="20" y2="20" stroke="#FF0000" stroke-width="2"/>
        <line x1="20" y1="4" x2="4" y2="20" stroke="#FF0000" stroke-width="2"/>
    </svg>
`;

// Function to check if fullscreen mode is active
function isFullscreenActive() {
    return document.fullscreenElement || document.mozFullScreenElement ||
           document.webkitFullscreenElement || document.msFullscreenElement;
}

// Function to enter fullscreen mode
function openFullScreen() {
    const elem = document.documentElement;  // Select the whole webpage
    if (elem.requestFullscreen) {
        elem.requestFullscreen();
    } else if (elem.mozRequestFullScreen) {  // For Firefox
        elem.mozRequestFullScreen();
    } else if (elem.webkitRequestFullscreen) {  // For Chrome, Safari, and Opera
        elem.webkitRequestFullscreen();
    } else if (elem.msRequestFullscreen) {  // For IE/Edge
        elem.msRequestFullscreen();
    }
}

// Function to exit fullscreen mode
function closeFullScreen() {
    if (document.exitFullscreen) {
        document.exitFullscreen();
    } else if (document.mozCancelFullScreen) {  // For Firefox
        document.mozCancelFullScreen();
    } else if (document.webkitExitFullscreen) {  // For Chrome, Safari, and Opera
        document.webkitExitFullscreen();
    } else if (document.msExitFullscreen) {  // For IE/Edge
        document.msExitFullscreen();
    }
}

// Function to toggle between fullscreen mode and regular mode
function toggleFullScreen() {
    if (isFullscreenActive()) {
        // If in fullscreen mode, exit fullscreen
        closeFullScreen();
    } else {
        // If not in fullscreen mode, enter fullscreen
        openFullScreen();
    }
    updateFullscreenIcon();
}

// Event listener for fullscreen change to keep the icon state in sync
document.addEventListener('fullscreenchange', updateFullscreenIcon);
document.addEventListener('webkitfullscreenchange', updateFullscreenIcon);  // For Webkit browsers
document.addEventListener('mozfullscreenchange', updateFullscreenIcon);      // For Firefox
document.addEventListener('MSFullscreenChange', updateFullscreenIcon);       // For IE/Edge

// Function to update the fullscreen icon based on the current fullscreen state
function updateFullscreenIcon() {
    const fullscreenIcon = document.getElementById('fullscreenIcon');
    if (!isFullscreenActive())
    {
        document.getElementById('fullscreenIcon').textContent = "⛶"; // Change icon back to 'enter fullscreen' icon
//        fullscreenIcon.innerHTML = FULLSCREEN_ENTER_ICON; // Change icon back to 'fullscreen off'
    }
    else
    {
        document.getElementById('fullscreenIcon').textContent = "❎"; // Change icon to a 'close fullscreen' icon (for example)
//        fullscreenIcon.innerHTML = FULLSCREEN_EXIT_ICON; // Change icon to 'fullscreen on' with red "X"

    }
}

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

document.addEventListener('DOMContentLoaded', () => {
    updateFullscreenIcon();
});


// Example usage: Display a message when the window resizes
// window.addEventListener('resize', function() {
//     const currentWidth = window.innerWidth;
//     const currentHeight = window.innerHeight;
//     console.log(`Browser resized: width=${currentWidth}, height=${currentHeight}`);
//     notificationMessage(`Browser resized: width=${currentWidth}, height=${currentHeight}`);
// });

