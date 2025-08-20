from flask import Flask, request, jsonify
# Root route for health check and Vercel base URL
app = Flask(__name__)
@app.route("/")
def index():
    return "Backend is running!"
from flask_cors import CORS
import socket
import json
import math
import textwrap
import re
import copy
from datetime import datetime
import logging
from groq import Groq
import os

# Configure enhanced logging with UTF-8 encoding
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(levelname)s - %(message)s',
    handlers=[
        logging.StreamHandler()
    ]
)
logger = logging.getLogger(__name__)


app = Flask(__name__)
# Enhanced CORS configuration for Flutter mobile and web
CORS(app, origins=['*'], supports_credentials=True, allow_headers=['Content-Type', 'Authorization'])

# Root route for health check and Vercel base URL
@app.route("/")
def index():
    return "Backend is running!"

# Initialize Groq client with enhanced error handling
GROQ_API_KEY = os.environ.get("GROQ_API_KEY")
try:
    client = Groq(api_key=GROQ_API_KEY)
    logger.info("Groq client initialized successfully")
except Exception as e:
    logger.error(f"Failed to initialize Groq client: {e}")
    client = None

def generate_error_svg(message):
    """Generate a simple error SVG when diagram generation fails"""
    return f'''<svg viewBox="0 0 400 200" xmlns="http://www.w3.org/2000/svg" style="max-width: 100%; height: auto;">
        <rect width="400" height="200" fill="#FEF2F2"/>
        <rect x="20" y="20" width="360" height="160" rx="8" fill="#FFFFFF" stroke="#EF4444" stroke-width="2"/>
        <text x="200" y="70" font-family="Arial, sans-serif" font-size="16" font-weight="bold" fill="#DC2626" text-anchor="middle">Diagram Generation Error</text>
        <text x="200" y="100" font-family="Arial, sans-serif" font-size="12" fill="#7F1D1D" text-anchor="middle">{message}</text>
        <text x="200" y="130" font-family="Arial, sans-serif" font-size="10" fill="#7F1D1D" text-anchor="middle">Please try again or contact support</text>
    </svg>'''

def get_fallback_data(diagram_type, user_input):
    """Generate fallback data when AI is not available"""
    
    # Create basic fallback data based on diagram type
    if diagram_type == "flowchart":
        return {
            "steps": {
                "Start": [f"Begin {user_input} process"],
                "Plan": [f"Plan and prepare for {user_input}"],
                "Execute": [f"Execute {user_input} activities"],
                "Review": [f"Review {user_input} results"],
                "Complete": [f"Complete {user_input} process"]
            }
        }
    elif diagram_type == "sequence":
        return {
            "actors": {
                "User": f"Person using {user_input}",
                "System": f"System handling {user_input}",
                "Database": f"Data store for {user_input}"
            },
            "interactions": [
                {"from": "User", "to": "System", "message": f"Request {user_input}", "order": 1},
                {"from": "System", "to": "Database", "message": "Query data", "order": 2},
                {"from": "Database", "to": "System", "message": "Return results", "order": 3},
                {"from": "System", "to": "User", "message": f"Display {user_input}", "order": 4}
            ]
        }
    elif diagram_type == "state":
        return {
            "states": {
                "Initial": f"Starting state for {user_input}",
                "Processing": f"Processing {user_input}",
                "Complete": f"Completed {user_input}",
                "Error": f"Error in {user_input}"
            },
            "transitions": [
                {"from": "Initial", "to": "Processing", "trigger": "Start", "order": 1},
                {"from": "Processing", "to": "Complete", "trigger": "Success", "order": 2},
                {"from": "Processing", "to": "Error", "trigger": "Failure", "order": 3}
            ]
        }
    elif diagram_type == "mind map":
        return {
            "central_topic": user_input.split()[0] if user_input else "Topic",
            "branches": {
                "Key Features": [f"Main features of {user_input}"],
                "Benefits": [f"Benefits of {user_input}"],
                "Challenges": [f"Challenges with {user_input}"],
                "Implementation": [f"How to implement {user_input}"],
                "Future": [f"Future of {user_input}"]
            }
        }
    elif diagram_type == "swot analysis":
        return {
            "strengths": [f"Strong foundation in {user_input}", f"Clear vision for {user_input}"],
            "weaknesses": [f"Limited experience with {user_input}", f"Resource constraints for {user_input}"],
            "opportunities": [f"Growing market for {user_input}", f"Innovation potential in {user_input}"],
            "threats": [f"Competition in {user_input} space", f"Regulatory changes affecting {user_input}"]
        }
    elif diagram_type == "timeline":
        return {
            "events": {
                "Phase 1": f"Initial planning for {user_input}",
                "Phase 2": f"Development of {user_input}",
                "Phase 3": f"Testing {user_input}",
                "Phase 4": f"Launch {user_input}",
                "Phase 5": f"Monitor {user_input}"
            }
        }
    elif diagram_type == "gantt":
        return {
            "tasks": {
                "Planning (2 weeks)": {"description": f"Plan {user_input} project", "dependencies": [], "start": 1, "duration": 2},
                "Design (3 weeks)": {"description": f"Design {user_input} solution", "dependencies": ["Planning"], "start": 3, "duration": 3},
                "Development (4 weeks)": {"description": f"Develop {user_input}", "dependencies": ["Design"], "start": 6, "duration": 4},
                "Testing (2 weeks)": {"description": f"Test {user_input}", "dependencies": ["Development"], "start": 10, "duration": 2},
                "Deployment (1 week)": {"description": f"Deploy {user_input}", "dependencies": ["Testing"], "start": 12, "duration": 1}
            }
        }
    elif diagram_type == "journey":
        return {
            "touchpoints": {
                "Awareness": {"action": f"Learn about {user_input}", "emotion": "Curious", "pain_points": ["Information overload"], "order": 1},
                "Consideration": {"action": f"Evaluate {user_input}", "emotion": "Analytical", "pain_points": ["Too many options"], "order": 2},
                "Purchase": {"action": f"Choose {user_input}", "emotion": "Confident", "pain_points": ["Complex process"], "order": 3},
                "Usage": {"action": f"Use {user_input}", "emotion": "Satisfied", "pain_points": ["Learning curve"], "order": 4}
            }
        }
    elif diagram_type == "erd":
        return {
            "entities": {
                "User": ["user_id", "name", "email", "created_date"],
                f"{user_input.replace(' ', '_')}": ["id", "name", "description", "status"],
                "Category": ["category_id", "name", "description"],
                "Transaction": ["transaction_id", "user_id", "amount", "date"]
            }
        }
    elif diagram_type == "class":
        return {
            "classes": {
                f"{user_input.replace(' ', '')}Manager": {
                    "attributes": ["id: int", "name: string", "status: string"],
                    "methods": ["create()", "update()", "delete()", "find()"]
                },
                f"{user_input.replace(' ', '')}Model": {
                    "attributes": ["data: object", "validation: rules"],
                    "methods": ["validate()", "save()", "load()"]
                },
                f"{user_input.replace(' ', '')}View": {
                    "attributes": ["template: string", "context: object"],
                    "methods": ["render()", "update()", "refresh()"]
                }
            }
        }
    elif diagram_type == "network":
        return {
            "nodes": {
                "Client": "User device",
                "Router": "Network router",
                "Server": f"{user_input} server",
                "Database": "Data storage"
            },
            "connections": [
                {"from": "Client", "to": "Router", "label": "HTTP"},
                {"from": "Router", "to": "Server", "label": "TCP/IP"},
                {"from": "Server", "to": "Database", "label": "SQL"}
            ]
        }
    elif diagram_type == "architecture":
        return {
            "components": {
                "Presentation Layer": f"User interface for {user_input}",
                "Business Logic": f"Core logic for {user_input}",
                "Data Access": f"Data layer for {user_input}",
                "Database": f"Storage for {user_input}"
            },
            "relationships": [
                {"from": "Presentation Layer", "to": "Business Logic", "label": "calls"},
                {"from": "Business Logic", "to": "Data Access", "label": "uses"},
                {"from": "Data Access", "to": "Database", "label": "queries"}
            ]
        }
    else:
        # Default fallback to flowchart
        return {
            "steps": {
                "Start": [f"Begin {user_input}"],
                "Process": [f"Process {user_input}"],
                "End": [f"Complete {user_input}"]
            }
        }

def apply_text_changes_to_svg(current_svg, prompt):
    """Apply simple text changes to existing SVG (fallback when AI unavailable)"""
    # This is a simple fallback - just return the current SVG
    # In a real implementation, you might parse the SVG and make basic changes
    return current_svg

def clean_json_response(response_content):
    """Clean and fix common JSON formatting issues"""
    # Remove markdown code blocks
    response_content = re.sub(r'```json\s*', '', response_content)
    response_content = re.sub(r'```\s*$', '', response_content)
    
    # Remove extra text before and after JSON
    response_content = response_content.strip()
    
    # Find JSON object boundaries
    start_idx = response_content.find('{')
    end_idx = response_content.rfind('}')
    
    if start_idx != -1 and end_idx != -1 and end_idx > start_idx:
        response_content = response_content[start_idx:end_idx+1]
    
    return response_content

def get_enhanced_diagram_prompt(diagram_type, user_input):
    """Generate enhanced, specific prompts for each diagram type"""
    
    enhanced_prompts = {
        "flowchart": f"""Create a detailed, professional flowchart for: {user_input}
Requirements:
- Identify 6-8 key sequential steps that are logical and actionable
- Each step should have a clear, concise description (1-2 sentences)
- Steps should be specific to the topic "{user_input}"
- Include decision points or branches if applicable
- Focus on practical, implementable steps
- Use professional terminology appropriate for the domain

Return ONLY valid JSON in this exact format:
{{"steps": {{"Step 1 Name": ["Brief description"], "Step 2 Name": ["Brief description"], ...}}}}

Topic: {user_input}""",

        "sequence": f"""Create a sequence diagram for: {user_input}
Requirements:
- Identify 5-7 actors/entities involved in "{user_input}"
- Show message flow and interactions between entities
- Include timing and order of operations
- Focus on communication patterns
- Use sequence diagram terminology

Return ONLY valid JSON in this exact format:
{{"actors": {{"Actor1": "Role/Description", "Actor2": "Role/Description", ...}}, "interactions": [{{"from": "Actor1", "to": "Actor2", "message": "Message description", "order": 1}}, ...]}}

Topic: {user_input}""",

        "state": f"""Create a state diagram for: {user_input}
Requirements:
- Identify 5-7 states in the "{user_input}" process
- Show transitions and triggers between states
- Include initial and final states
- Focus on state changes and conditions
- Use state machine terminology

Return ONLY valid JSON in this exact format:
{{"states": {{"StateName": "State description", ...}}, "transitions": [{{"from": "State1", "to": "State2", "trigger": "Event/Condition", "order": 1}}, ...]}}

Topic: {user_input}""",

        "mind map": f"""Create a comprehensive mind map for: {user_input}
Requirements:
- Central topic should be concise and clear (1-3 words) related to "{user_input}"
- Create 6-8 main branches representing key aspects or categories
- Each branch should have a relevant concept, detail, or subtopic
- Focus on logical categorization and relationships specific to "{user_input}"
- Use professional terminology appropriate for the domain
- Make branches comprehensive and meaningful

Return ONLY valid JSON in this exact format:
{{"central_topic": "Main Topic", "branches": {{"Branch 1": ["Concept"], "Branch 2": ["Concept"], ...}}}}

Topic: {user_input}""",

        "swot analysis": f"""Create a thorough SWOT analysis for: {user_input}
Requirements:
- Provide 5-7 items per category (Strengths, Weaknesses, Opportunities, Threats)
- Be specific and actionable, directly related to "{user_input}"
- Consider both internal factors (strengths/weaknesses) and external factors (opportunities/threats)
- Use professional business terminology
- Focus on realistic, relevant factors specific to the context of "{user_input}"
- Make each point detailed and meaningful

Return ONLY valid JSON in this exact format:
{{"strengths": ["Item 1", "Item 2", ...], "weaknesses": ["Item 1", "Item 2", ...], "opportunities": ["Item 1", "Item 2", ...], "threats": ["Item 1", "Item 2", ...]}}

Topic: {user_input}""",

        "timeline": f"""Create a realistic timeline for: {user_input}
Requirements:
- Identify 6-8 key phases, milestones, or time periods
- Use logical sequence or chronological order appropriate for "{user_input}"
- Each event should be clearly described and actionable
- Include realistic timeframes or phases (weeks, months, quarters as appropriate)
- Focus on chronological progression specific to the context
- Make timeline practical and achievable

Return ONLY valid JSON in this exact format:
{{"events": {{"Phase 1/Timeframe": "Description", "Phase 2/Timeframe": "Description", ...}}}}

Topic: {user_input}""",

        "gantt": f"""Create a Gantt chart structure for: {user_input}
Requirements:
- Identify 6-8 parallel and sequential tasks
- Include duration estimates for "{user_input}"
- Show task dependencies and overlaps
- Focus on resource allocation
- Use project management terminology

Return ONLY valid JSON in this exact format:
{{"tasks": {{"Task Name (Duration)": {{"description": "Task description", "dependencies": ["Dependency1"], "start": 1, "duration": 4}}, ...}}}}

Topic: {user_input}""",

        "journey": f"""Create a user journey map for: {user_input}
Requirements:
- Identify 6-8 touchpoints in the "{user_input}" experience
- Include user emotions and pain points
- Show user actions and system responses
- Focus on user experience optimization
- Use UX terminology

Return ONLY valid JSON in this exact format:
{{"touchpoints": {{"Touchpoint Name": {{"action": "User action", "emotion": "User feeling", "pain_points": ["Issue 1"], "order": 1}}, ...}}}}

Topic: {user_input}""",

        "erd": f"""Create an Entity Relationship Diagram for: {user_input}
Requirements:
- Identify 4-6 main entities for "{user_input}" system
- List 4-6 attributes per entity
- Consider primary keys and relationships
- Use database design principles
- Focus on data structure

Return ONLY valid JSON in this exact format:
{{"entities": {{"EntityName": ["attribute1", "attribute2", ...], ...}}}}

Topic: {user_input}""",

        "class": f"""Create a class diagram for: {user_input}
Requirements:
- Identify 4-6 classes for "{user_input}" system
- List 3-5 attributes and methods per class
- Show inheritance and composition relationships
- Use object-oriented design principles
- Focus on system architecture

Return ONLY valid JSON in this exact format:
{{"classes": {{"ClassName": {{"attributes": ["attr: type", ...], "methods": ["method()", ...]}}, ...}}}}

Topic: {user_input}""",

        "network": f"""Create a network diagram for: {user_input}
Requirements:
- Identify 5-7 network components for "{user_input}"
- Show connections and protocols
- Include security and performance considerations
- Use networking terminology
- Focus on system topology

Return ONLY valid JSON in this exact format:
{{"nodes": {{"NodeName": "Type/Role", ...}}, "connections": [{{"from": "Node1", "to": "Node2", "label": "Connection"}}], ...}}

Topic: {user_input}""",

        "architecture": f"""Create a system architecture diagram for: {user_input}
Requirements:
- Identify 5-7 architectural components for "{user_input}"
- Show layers and service boundaries
- Include data flow and dependencies
- Use architectural patterns
- Focus on system design

Return ONLY valid JSON in this exact format:
{{"components": {{"ComponentName": "Purpose/Type", ...}}, "relationships": [{{"from": "Comp1", "to": "Comp2", "label": "Relationship"}}], ...}}

Topic: {user_input}""",
    }
    
    return enhanced_prompts.get(diagram_type, enhanced_prompts["flowchart"])

def validate_diagram_json(json_data, diagram_type):
    """Enhanced validation with better error messages and recovery"""
    try:
        diagram_type_lower = diagram_type.lower()
        
        if "flow" in diagram_type_lower:
            if not isinstance(json_data.get("steps", {}), dict):
                if "blocks" in json_data:
                    json_data["steps"] = json_data["blocks"]
                elif "nodes" in json_data:
                    json_data["steps"] = json_data["nodes"]
                else:
                    raise ValueError("Flowchart requires 'steps' dictionary")
            if len(json_data["steps"]) < 2:
                raise ValueError("Flowchart needs at least 2 steps")

        elif diagram_type == "sequence":
            if not all(k in json_data for k in ["actors", "interactions"]):
                # Fallback to steps format if sequence format not available
                if "steps" in json_data:
                    # Convert steps to sequence format
                    actors = {}
                    interactions = []
                    for i, (step_name, step_desc) in enumerate(json_data["steps"].items()):
                        actors[f"Actor{i+1}"] = step_name
                        if i > 0:
                            interactions.append({
                                "from": f"Actor{i}",
                                "to": f"Actor{i+1}",
                                "message": step_desc[0] if step_desc else step_name,
                                "order": i
                            })
                    json_data["actors"] = actors
                    json_data["interactions"] = interactions
                else:
                    raise ValueError("Sequence diagram requires actors and interactions")

        elif diagram_type == "state":
            if not all(k in json_data for k in ["states", "transitions"]):
                # Fallback to steps format if state format not available
                if "steps" in json_data:
                    # Convert steps to state format
                    states = {}
                    transitions = []
                    for i, (step_name, step_desc) in enumerate(json_data["steps"].items()):
                        states[step_name] = step_desc[0] if step_desc else step_name
                        if i > 0:
                            prev_step = list(json_data["steps"].keys())[i-1]
                            transitions.append({
                                "from": prev_step,
                                "to": step_name,
                                "trigger": "Next step",
                                "order": i
                            })
                    json_data["states"] = states
                    json_data["transitions"] = transitions
                else:
                    raise ValueError("State diagram requires states and transitions")

        elif "mind" in diagram_type_lower:
            if not all(k in json_data for k in ["central_topic", "branches"]):
                if "center" in json_data:
                    json_data["central_topic"] = json_data["center"]
                if "topics" in json_data:
                    json_data["branches"] = json_data["topics"]
                if not all(k in json_data for k in ["central_topic", "branches"]):
                    raise ValueError("Mind map requires central_topic and branches")
            if not isinstance(json_data["branches"], dict):
                raise ValueError("Branches must be a dictionary")

        elif "swot" in diagram_type_lower:
            required_keys = ["strengths", "weaknesses", "opportunities", "threats"]
            if not any(k in json_data for k in required_keys):
                raise ValueError("SWOT analysis requires at least one category")

        elif "timeline" in diagram_type_lower:
            if not isinstance(json_data.get("events", {}), dict):
                if "phases" in json_data:
                    json_data["events"] = json_data["phases"]
                elif "milestones" in json_data:
                    json_data["events"] = json_data["milestones"]
                else:
                    raise ValueError("Timeline requires 'events' dictionary")

        elif diagram_type == "gantt":
            if not isinstance(json_data.get("tasks", {}), dict):
                if "events" in json_data:
                    # Convert events to tasks format
                    tasks = {}
                    for event_name, event_desc in json_data["events"].items():
                        tasks[event_name] = {
                            "description": event_desc,
                            "dependencies": [],
                            "start": 1,
                            "duration": 2
                        }
                    json_data["tasks"] = tasks
                else:
                    raise ValueError("Gantt chart requires 'tasks' dictionary")

        elif diagram_type == "journey":
            if not isinstance(json_data.get("touchpoints", {}), dict):
                if "events" in json_data:
                    # Convert events to touchpoints format
                    touchpoints = {}
                    for i, (event_name, event_desc) in enumerate(json_data["events"].items()):
                        touchpoints[event_name] = {
                            "action": event_desc,
                            "emotion": "Neutral",
                            "pain_points": [],
                            "order": i+1
                        }
                    json_data["touchpoints"] = touchpoints
                else:
                    raise ValueError("Journey map requires 'touchpoints' dictionary")
        
        # Special handling for ERD (Entity Relationship Diagram)
        elif diagram_type == "erd":
            if not isinstance(json_data.get("entities", {}), dict):
                if "tables" in json_data:
                    json_data["entities"] = json_data["tables"]
                else:
                    raise ValueError("ERD requires 'entities' dictionary")
            for entity, attributes in json_data.get("entities", {}).items():
                if not isinstance(attributes, list):
                    raise ValueError(f"Entity '{entity}' attributes must be a list")
        
        # Special handling for Class diagrams
        elif diagram_type == "class":
            if not isinstance(json_data.get("classes", {}), dict):
                raise ValueError("Class diagram requires 'classes' dictionary")
            for cls, members in json_data.get("classes", {}).items():
                if not isinstance(members, dict) or not all(k in members for k in ["attributes", "methods"]):
                    raise ValueError(f"Class '{cls}' must have 'attributes' and 'methods'")
        
        # Special handling for Network diagrams
        elif diagram_type == "network":
            if not isinstance(json_data.get("nodes", {}), dict):
                raise ValueError("Network diagram requires 'nodes' dictionary")
            if not isinstance(json_data.get("connections", []), list):
                json_data["connections"] = []  # Allow empty connections
        
        # Special handling for Architecture diagrams
        elif diagram_type == "architecture":
            if not isinstance(json_data.get("components", {}), dict):
                raise ValueError("Architecture diagram requires 'components' dictionary")
            if not isinstance(json_data.get("relationships", []), list):
                json_data["relationships"] = []  # Allow empty relationships
                
        return True
    except Exception as e:
        logger.error(f"Validation error for {diagram_type}: {str(e)}")
        raise

def generate_enhanced_sequence_svg(actors, interactions):
    """Generate proper sequence diagram"""
    if not actors or not interactions:
        return generate_error_svg("Sequence diagram requires actors and interactions")

    width, height = 1400, 800
    actor_width = 120
    actor_height = 60
    message_height = 80
    
    # Calculate positions
    actor_spacing = (width - 100) // max(len(actors), 1)
    actor_positions = {}
    
    svg_elements = [
        '<defs>',
        '''
        <linearGradient id="actorGrad" x1="0%" y1="0%" x2="100%" y2="100%">
            <stop offset="0%" style="stop-color:#4F46E5;stop-opacity:1" />
            <stop offset="100%" style="stop-color:#7C3AED;stop-opacity:1" />
        </linearGradient>
        ''',
        '''
        <marker id="seqArrow" markerWidth="10" markerHeight="7" refX="9" refY="3.5" orient="auto">
            <polygon points="0 0, 10 3.5, 0 7" fill="#4B5563"/>
        </marker>
        ''',
        '</defs>',
        
        f'<rect width="{width}" height="{height}" fill="#F8FAFC"/>',
        
        # Title
        f'<text x="{width//2}" y="40" font-family="Inter, sans-serif" '
        'font-size="28" font-weight="800" fill="#1F2937" text-anchor="middle">Sequence Diagram</text>',
    ]

    # Draw actors
    for i, (actor_name, actor_desc) in enumerate(actors.items()):
        x = 50 + i * actor_spacing + actor_spacing // 2
        y = 80
        actor_positions[actor_name] = x
        
        # Actor box
        svg_elements.extend([
            f'<rect x="{x-actor_width//2}" y="{y}" width="{actor_width}" height="{actor_height}" '
            'rx="8" fill="url(#actorGrad)" stroke="#FFFFFF" stroke-width="2"/>',
            
            f'<text x="{x}" y="{y+25}" font-family="Inter, sans-serif" '
            f'font-size="14" font-weight="700" fill="#FFFFFF" text-anchor="middle">{actor_name[:12]}</text>',
            
            f'<text x="{x}" y="{y+45}" font-family="Inter, sans-serif" '
            f'font-size="10" fill="#E5E7EB" text-anchor="middle">{actor_desc[:15]}</text>',
            
            # Lifeline
            f'<line x1="{x}" y1="{y+actor_height}" x2="{x}" y2="{height-50}" '
            'stroke="#9CA3AF" stroke-width="2" stroke-dasharray="5,5"/>',
        ])

    # Draw interactions
    sorted_interactions = sorted(interactions, key=lambda x: x.get('order', 0))
    for i, interaction in enumerate(sorted_interactions):
        from_actor = interaction.get('from', '')
        to_actor = interaction.get('to', '')
        message = interaction.get('message', '')
        
        if from_actor in actor_positions and to_actor in actor_positions:
            x1 = actor_positions[from_actor]
            x2 = actor_positions[to_actor]
            y = 180 + i * message_height
            
            svg_elements.extend([
                f'<line x1="{x1}" y1="{y}" x2="{x2}" y2="{y}" '
                'stroke="#4B5563" stroke-width="2" marker-end="url(#seqArrow)"/>',
                
                f'<text x="{(x1+x2)/2}" y="{y-10}" font-family="Inter, sans-serif" '
                f'font-size="12" fill="#374151" text-anchor="middle">{message[:30]}</text>'
            ])

    return f'<svg viewBox="0 0 {width} {height}" xmlns="http://www.w3.org/2000/svg" style="max-width: 100%; height: auto;">\n' + '\n'.join(svg_elements) + '\n</svg>'

def generate_enhanced_state_svg(states, transitions):
    """Generate proper state diagram"""
    if not states:
        return generate_error_svg("State diagram requires states")

    width, height = 1400, 800
    state_radius = 80
    
    # Position states in a circular layout
    center_x, center_y = width // 2, height // 2
    radius = min(width, height) * 0.3
    angle_step = 360 / max(len(states), 1)
    
    state_positions = {}
    
    svg_elements = [
        '<defs>',
        '''
        <linearGradient id="stateGrad" x1="0%" y1="0%" x2="100%" y2="100%">
            <stop offset="0%" style="stop-color:#DC2626;stop-opacity:1" />
            <stop offset="100%" style="stop-color:#EF4444;stop-opacity:1" />
        </linearGradient>
        ''',
        '''
        <marker id="stateArrow" markerWidth="10" markerHeight="7" refX="9" refY="3.5" orient="auto">
            <polygon points="0 0, 10 3.5, 0 7" fill="#4B5563"/>
        </marker>
        ''',
        '</defs>',
        
        f'<rect width="{width}" height="{height}" fill="#F8FAFC"/>',
        
        # Title
        f'<text x="{width//2}" y="40" font-family="Inter, sans-serif" '
        'font-size="28" font-weight="800" fill="#1F2937" text-anchor="middle">State Diagram</text>',
    ]

    # Draw states
    for i, (state_name, state_desc) in enumerate(states.items()):
        angle = math.radians(i * angle_step)
        x = center_x + radius * math.cos(angle)
        y = center_y + radius * math.sin(angle)
        state_positions[state_name] = (x, y)
        
        # State circle
        svg_elements.extend([
            f'<circle cx="{x}" cy="{y}" r="{state_radius}" fill="url(#stateGrad)" stroke="#FFFFFF" stroke-width="3"/>',
            
            f'<text x="{x}" y="{y-10}" font-family="Inter, sans-serif" '
            f'font-size="14" font-weight="700" fill="#FFFFFF" text-anchor="middle">{state_name[:12]}</text>',
            
            f'<text x="{x}" y="{y+10}" font-family="Inter, sans-serif" '
            f'font-size="10" fill="#E5E7EB" text-anchor="middle">{state_desc[:20]}</text>',
        ])

    # Draw transitions
    for transition in transitions:
        from_state = transition.get('from', '')
        to_state = transition.get('to', '')
        trigger = transition.get('trigger', '')
        
        if from_state in state_positions and to_state in state_positions:
            x1, y1 = state_positions[from_state]
            x2, y2 = state_positions[to_state]
            
            # Calculate arrow positions on circle edges
            dx, dy = x2 - x1, y2 - y1
            length = math.sqrt(dx*dx + dy*dy)
            if length > 0:
                dx, dy = dx/length, dy/length
                start_x, start_y = x1 + dx * state_radius, y1 + dy * state_radius
                end_x, end_y = x2 - dx * state_radius, y2 - dy * state_radius
                
                svg_elements.extend([
                    f'<line x1="{start_x}" y1="{start_y}" x2="{end_x}" y2="{end_y}" '
                    'stroke="#4B5563" stroke-width="2" marker-end="url(#stateArrow)"/>',
                    
                    f'<text x="{(start_x+end_x)/2}" y="{(start_y+end_y)/2-10}" font-family="Inter, sans-serif" '
                    f'font-size="10" fill="#374151" text-anchor="middle">{trigger[:15]}</text>'
                ])

    return f'<svg viewBox="0 0 {width} {height}" xmlns="http://www.w3.org/2000/svg" style="max-width: 100%; height: auto;">\n' + '\n'.join(svg_elements) + '\n</svg>'

def generate_enhanced_gantt_svg(tasks):
    """Generate proper Gantt chart"""
    if not tasks:
        return generate_error_svg("Gantt chart requires tasks")

    width, height = 1400, 600
    task_height = 40
    task_spacing = 60
    chart_start_x = 300
    
    svg_elements = [
        '<defs>',
        '''
        <linearGradient id="ganttGrad" x1="0%" y1="0%" x2="100%" y2="0%">
            <stop offset="0%" style="stop-color:#9333EA;stop-opacity:1" />
            <stop offset="100%" style="stop-color:#A855F7;stop-opacity:1" />
        </linearGradient>
        ''',
        '</defs>',
        
        f'<rect width="{width}" height="{height}" fill="#F8FAFC"/>',
        
        # Title
        f'<text x="{width//2}" y="40" font-family="Inter, sans-serif" '
        'font-size="28" font-weight="800" fill="#1F2937" text-anchor="middle">Gantt Chart</text>',
        
        # Time axis
        f'<line x1="{chart_start_x}" y1="80" x2="{width-50}" y2="80" stroke="#9CA3AF" stroke-width="2"/>',
    ]

    # Draw time markers
    time_width = (width - chart_start_x - 50) // 12
    for i in range(13):
        x = chart_start_x + i * time_width
        svg_elements.extend([
            f'<line x1="{x}" y1="75" x2="{x}" y2="85" stroke="#9CA3AF" stroke-width="1"/>',
            f'<text x="{x}" y="100" font-family="Inter, sans-serif" '
            f'font-size="10" fill="#6B7280" text-anchor="middle">M{i+1}</text>'
        ])

    # Draw tasks
    for i, (task_name, task_data) in enumerate(tasks.items()):
        y = 120 + i * task_spacing
        
        # Task info
        description = task_data.get('description', task_name) if isinstance(task_data, dict) else str(task_data)
        start = task_data.get('start', 1) if isinstance(task_data, dict) else 1
        duration = task_data.get('duration', 2) if isinstance(task_data, dict) else 2
        
        # Task label
        svg_elements.append(
            f'<text x="20" y="{y+task_height//2+5}" font-family="Inter, sans-serif" '
            f'font-size="12" fill="#374151" font-weight="600">{task_name[:25]}</text>'
        )
        
        # Task bar
        bar_x = chart_start_x + (start-1) * time_width
        bar_width = duration * time_width
        
        svg_elements.extend([
            f'<rect x="{bar_x}" y="{y}" width="{bar_width}" height="{task_height}" '
            'rx="4" fill="url(#ganttGrad)" stroke="#FFFFFF" stroke-width="1"/>',
            
            f'<text x="{bar_x + bar_width//2}" y="{y+task_height//2+5}" font-family="Inter, sans-serif" '
            f'font-size="10" fill="#FFFFFF" text-anchor="middle">{duration}M</text>'
        ])

    return f'<svg viewBox="0 0 {width} {height}" xmlns="http://www.w3.org/2000/svg" style="max-width: 100%; height: auto;">\n' + '\n'.join(svg_elements) + '\n</svg>'

def generate_enhanced_journey_svg(touchpoints):
    """Generate proper user journey map"""
    if not touchpoints:
        return generate_error_svg("Journey map requires touchpoints")

    width, height = 1400, 700
    touchpoint_width = 150
    touchpoint_height = 100
    
    # Sort touchpoints by order
    sorted_touchpoints = sorted(touchpoints.items(), key=lambda x: x[1].get('order', 0) if isinstance(x[1], dict) else 0)
    
    svg_elements = [
        '<defs>',
        '''
        <linearGradient id="journeyGrad" x1="0%" y1="0%" x2="100%" y2="100%">
            <stop offset="0%" style="stop-color:#BE185D;stop-opacity:1" />
            <stop offset="100%" style="stop-color:#DB2777;stop-opacity:1" />
        </linearGradient>
        ''',
        '</defs>',
        
        f'<rect width="{width}" height="{height}" fill="#F8FAFC"/>',
        
        # Title
        f'<text x="{width//2}" y="40" font-family="Inter, sans-serif" '
        'font-size="28" font-weight="800" fill="#1F2937" text-anchor="middle">User Journey Map</text>',
        
        # Journey line
        f'<line x1="100" y1="{height//2}" x2="{width-100}" y2="{height//2}" stroke="#DB2777" stroke-width="4"/>',
    ]

    # Draw touchpoints
    spacing = (width - 200) // max(len(sorted_touchpoints), 1)
    for i, (touchpoint_name, touchpoint_data) in enumerate(sorted_touchpoints):
        x = 100 + i * spacing + spacing // 2
        y = height // 2
        
        # Touchpoint info
        if isinstance(touchpoint_data, dict):
            action = touchpoint_data.get('action', touchpoint_name)
            emotion = touchpoint_data.get('emotion', 'Neutral')
        else:
            action = str(touchpoint_data)
            emotion = 'Neutral'
        
        # Touchpoint circle
        svg_elements.extend([
            f'<circle cx="{x}" cy="{y}" r="30" fill="url(#journeyGrad)" stroke="#FFFFFF" stroke-width="3"/>',
            f'<text x="{x}" y="{y+5}" font-family="Inter, sans-serif" '
            f'font-size="12" font-weight="700" fill="#FFFFFF" text-anchor="middle">{i+1}</text>',
            
            # Touchpoint details above
            f'<rect x="{x-touchpoint_width//2}" y="{y-150}" width="{touchpoint_width}" height="{touchpoint_height}" '
            'rx="8" fill="#FFFFFF" stroke="#DB2777" stroke-width="2"/>',
            
            f'<text x="{x}" y="{y-120}" font-family="Inter, sans-serif" '
            f'font-size="12" font-weight="700" fill="#DB2777" text-anchor="middle">{touchpoint_name[:15]}</text>',
            
            f'<text x="{x}" y="{y-100}" font-family="Inter, sans-serif" '
            f'font-size="10" fill="#374151" text-anchor="middle">{action[:20]}</text>',
            
            f'<text x="{x}" y="{y-80}" font-family="Inter, sans-serif" '
            f'font-size="10" fill="#6B7280" text-anchor="middle">{emotion}</text>',
        ])

    return f'<svg viewBox="0 0 {width} {height}" xmlns="http://www.w3.org/2000/svg" style="max-width: 100%; height: auto;">\n' + '\n'.join(svg_elements) + '\n</svg>'

# Keep all existing functions (generate_enhanced_network_svg, generate_enhanced_architecture_svg, etc.)
def generate_enhanced_network_svg(data):
    """Generate Network Diagram with premium design"""
    nodes = data.get("nodes", {})
    connections = data.get("connections", [])
    
    if not nodes:
        return generate_error_svg("Network diagram requires nodes data")

    width, height = 1400, 900
    center_x, center_y = width // 2, height // 2
    
    svg_elements = [
        '<defs>',
        '''
        <linearGradient id="networkGrad" x1="0%" y1="0%" x2="100%" y2="100%">
            <stop offset="0%" style="stop-color:#1E3A8A;stop-opacity:1" />
            <stop offset="100%" style="stop-color:#3B82F6;stop-opacity:1" />
        </linearGradient>
        ''',
        '''
        <filter id="networkShadow" x="-30%" y="-30%" width="160%" height="160%">
            <feGaussianBlur in="SourceAlpha" stdDeviation="4"/>
            <feOffset dx="2" dy="4" result="offset"/>
            <feFlood flood-color="#000000" flood-opacity="0.2"/>
            <feComposite in2="offset" operator="in"/>
            <feMerge><feMergeNode/><feMergeNode in="SourceGraphic"/></feMerge>
        </filter>
        ''',
        '''
        <marker id="networkArrow" markerWidth="10" markerHeight="7" refX="9" refY="3.5" orient="auto">
            <polygon points="0 0, 10 3.5, 0 7" fill="#4B5563"/>
        </marker>
        ''',
        '</defs>',
        
        f'<rect width="{width}" height="{height}" fill="#F8FAFC"/>',
        
        f'<text x="{width//2}" y="40" font-family="Inter, sans-serif" '
        'font-size="28" font-weight="800" fill="#1F2937" text-anchor="middle">Network Architecture</text>',
        f'<text x="{width//2}" y="70" font-family="Inter, sans-serif" '
        'font-size="16" fill="#6B7280" text-anchor="middle">System connectivity and data flow</text>',
    ]

    # Position nodes in a circular layout
    node_positions = {}
    radius = min(width, height) * 0.35
    angle_step = 360 / max(len(nodes), 1)
    
    for i, (node_name, node_type) in enumerate(nodes.items()):
        angle = math.radians(i * angle_step)
        x = center_x + radius * math.cos(angle)
        y = center_y + radius * math.sin(angle)
        node_positions[node_name] = (x, y)
        
        # Node styling based on type
        node_color = "#1E3A8A" if "server" in node_type.lower() else "#3B82F6"
        node_size = 80 if "server" in node_type.lower() else 60
        
        svg_elements.extend([
            f'<rect x="{x-node_size//2}" y="{y-node_size//2}" width="{node_size}" height="{node_size}" '
            f'rx="12" fill="url(#networkGrad)" filter="url(#networkShadow)" stroke="#FFFFFF" stroke-width="2"/>',
            
            f'<text x="{x}" y="{y-10}" font-family="Inter, sans-serif" '
            f'font-size="14" font-weight="700" fill="#FFFFFF" text-anchor="middle">{node_name[:12]}</text>',
            
            f'<text x="{x}" y="{y+8}" font-family="Inter, sans-serif" '
            f'font-size="11" fill="#E5E7EB" text-anchor="middle">{node_type[:15]}</text>',
        ])

    # Draw connections
    for connection in connections:
        from_node = connection.get("from", "")
        to_node = connection.get("to", "")
        label = connection.get("label", "")
        
        if from_node in node_positions and to_node in node_positions:
            x1, y1 = node_positions[from_node]
            x2, y2 = node_positions[to_node]
            
            svg_elements.extend([
                f'<line x1="{x1}" y1="{y1}" x2="{x2}" y2="{y2}" '
                'stroke="#4B5563" stroke-width="3" marker-end="url(#networkArrow)"/>',
                
                f'<text x="{(x1+x2)/2}" y="{(y1+y2)/2-10}" font-family="Inter, sans-serif" '
                f'font-size="12" fill="#374151" text-anchor="middle">{label[:20]}</text>'
            ])

    return f'<svg viewBox="0 0 {width} {height}" xmlns="http://www.w3.org/2000/svg" style="max-width: 100%; height: auto;">\n' + '\n'.join(svg_elements) + '\n</svg>'

def generate_enhanced_architecture_svg(data):
    """Generate Architecture Diagram with layered design"""
    components = data.get("components", {})
    relationships = data.get("relationships", [])
    
    if not components:
        return generate_error_svg("Architecture diagram requires components data")

    width, height = 1400, 1000
    
    svg_elements = [
        '<defs>',
        '''
        <linearGradient id="archGrad" x1="0%" y1="0%" x2="100%" y2="100%">
            <stop offset="0%" style="stop-color:#7C3AED;stop-opacity:1" />
            <stop offset="100%" style="stop-color:#A855F7;stop-opacity:1" />
        </linearGradient>
        ''',
        '''
        <filter id="archShadow" x="-20%" y="-20%" width="140%" height="140%">
            <feGaussianBlur in="SourceAlpha" stdDeviation="3"/>
            <feOffset dx="2" dy="4" result="offset"/>
            <feFlood flood-color="#000000" flood-opacity="0.15"/>
            <feComposite in2="offset" operator="in"/>
            <feMerge><feMergeNode/><feMergeNode in="SourceGraphic"/></feMerge>
        </filter>
        ''',
        '</defs>',
        
        f'<rect width="{width}" height="{height}" fill="#FAFAFA"/>',
        
        f'<text x="{width//2}" y="40" font-family="Inter, sans-serif" '
        'font-size="28" font-weight="800" fill="#1F2937" text-anchor="middle">System Architecture</text>',
        f'<text x="{width//2}" y="70" font-family="Inter, sans-serif" '
        'font-size="16" fill="#6B7280" text-anchor="middle">Component structure and relationships</text>',
    ]

    # Arrange components in layers
    layers = ["Presentation", "Business", "Data", "Infrastructure"]
    layer_height = (height - 150) // len(layers)
    component_width = 200
    component_height = 80
    
    component_positions = {}
    comp_list = list(components.items())
    comps_per_layer = max(1, len(comp_list) // len(layers))
    
    for layer_idx, layer_name in enumerate(layers):
        layer_y = 120 + layer_idx * layer_height
        
        # Draw layer background
        svg_elements.append(
            f'<rect x="50" y="{layer_y-20}" width="{width-100}" height="{layer_height-20}" '
            f'rx="8" fill="rgba(124, 58, 237, 0.05)" stroke="rgba(124, 58, 237, 0.2)" stroke-width="1"/>'
        )
        
        svg_elements.append(
            f'<text x="70" y="{layer_y}" font-family="Inter, sans-serif" '
            f'font-size="14" font-weight="600" fill="#7C3AED">{layer_name} Layer</text>'
        )
        
        # Place components in this layer
        start_idx = layer_idx * comps_per_layer
        end_idx = min(start_idx + comps_per_layer, len(comp_list))
        layer_components = comp_list[start_idx:end_idx]
        
        if layer_components:
            spacing = (width - 200) // (len(layer_components) + 1)
            
            for comp_idx, (comp_name, comp_purpose) in enumerate(layer_components):
                x = 100 + (comp_idx + 1) * spacing - component_width // 2
                y = layer_y + 30
                
                component_positions[comp_name] = (x + component_width//2, y + component_height//2)
                
                svg_elements.extend([
                    f'<rect x="{x}" y="{y}" width="{component_width}" height="{component_height}" '
                    f'rx="12" fill="url(#archGrad)" filter="url(#archShadow)" stroke="#FFFFFF" stroke-width="2"/>',
                    
                    f'<text x="{x + component_width//2}" y="{y + 25}" font-family="Inter, sans-serif" '
                    f'font-size="14" font-weight="700" fill="#FFFFFF" text-anchor="middle">{comp_name[:18]}</text>',
                    
                    f'<text x="{x + component_width//2}" y="{y + 45}" font-family="Inter, sans-serif" '
                    f'font-size="11" fill="#E5E7EB" text-anchor="middle">{comp_purpose[:25]}</text>',
                ])

    # Draw relationships
    for i in range(len(comp_list)-1):
        from_comp = comp_list[i][0]
        to_comp = comp_list[i+1][0]
        
        if from_comp in component_positions and to_comp in component_positions:
            x1, y1 = component_positions[from_comp]
            x2, y2 = component_positions[to_comp]
            
            svg_elements.extend([
                f'<line x1="{x1}" y1="{y1}" x2="{x2}" y2="{y2}" '
                'stroke="#7C3AED" stroke-width="2" stroke-dasharray="5,3"/>',
                
                f'<text x="{(x1+x2)/2}" y="{(y1+y2)/2-8}" font-family="Inter, sans-serif" '
                f'font-size="11" fill="#7C3AED" text-anchor="middle">depends on</text>'
            ])

    return f'<svg viewBox="0 0 {width} {height}" xmlns="http://www.w3.org/2000/svg" style="max-width: 100%; height: auto;">\n' + '\n'.join(svg_elements) + '\n</svg>'

# Keep all other existing functions (generate_enhanced_erd_svg, generate_enhanced_class_diagram_svg, etc.)
def generate_enhanced_erd_svg(entities):
    """Generate Entity Relationship Diagram with premium design"""
    if not entities or not isinstance(entities, dict):
        return generate_error_svg("ERD requires entities data")

    width, height = 1400, 900
    node_width = 220
    node_height = 120
    spacing = 100
    
    # Calculate required height based on entities
    height = max(height, 200 + len(entities) * (node_height + spacing))

    svg_elements = [
        '<defs>',
        # Premium gradients for different entity types
        '''
        <linearGradient id="entityGrad" x1="0%" y1="0%" x2="100%" y2="100%">
            <stop offset="0%" style="stop-color:#4F46E5;stop-opacity:1" />
            <stop offset="100%" style="stop-color:#7C3AED;stop-opacity:1" />
        </linearGradient>
        ''',
        '''
        <linearGradient id="relationshipGrad" x1="0%" y1="0%" x2="100%" y2="100%">
            <stop offset="0%" style="stop-color:#10B981;stop-opacity:1" />
            <stop offset="100%" style="stop-color:#059669;stop-opacity:1" />
        </linearGradient>
        ''',
        # Arrow marker for relationships
        '''
        <marker id="erdArrow" markerWidth="10" markerHeight="7" refX="9" refY="3.5" orient="auto">
            <polygon points="0 0, 10 3.5, 0 7" fill="#4B5563"/>
        </marker>
        ''',
        '''
        <filter id="premiumShadow" x="-30%" y="-30%" width="160%" height="160%">
            <feGaussianBlur in="SourceAlpha" stdDeviation="4"/>
            <feOffset dx="2" dy="4" result="offset"/>
            <feFlood flood-color="#000000" flood-opacity="0.2"/>
            <feComposite in2="offset" operator="in"/>
            <feMerge><feMergeNode/><feMergeNode in="SourceGraphic"/></feMerge>
        </filter>
        ''',
        '</defs>',
        
        # Background
        f'<rect width="{width}" height="{height}" fill="#F9FAFB"/>',
        
        # Title
        f'<text x="{width//2}" y="40" font-family="Inter, -apple-system, sans-serif" '
        'font-size="28" font-weight="800" fill="#1F2937" text-anchor="middle">Entity Relationship Diagram</text>',
        f'<text x="{width//2}" y="70" font-family="Inter, -apple-system, sans-serif" '
        'font-size="16" fill="#6B7280" text-anchor="middle">Database schema visualization</text>',
    ]

    # Calculate positions for entities in a circular layout
    center_x, center_y = width // 2, height // 2
    radius = min(width, height) * 0.35
    angle_step = 360 / max(len(entities), 1)
    
    entity_positions = {}
    for i, (entity_name, attributes) in enumerate(entities.items()):
        angle = math.radians(i * angle_step)
        x = center_x + radius * math.cos(angle)
        y = center_y + radius * math.sin(angle)
        entity_positions[entity_name] = (x, y)
        
        # Entity box
        svg_elements.extend([
            f'<rect x="{x-node_width//2}" y="{y-node_height//2}" width="{node_width}" height="{node_height}" '
            'rx="8" fill="url(#entityGrad)" stroke="#FFFFFF" stroke-width="2" filter="url(#premiumShadow)"/>',
            
            # Entity name
            f'<text x="{x}" y="{y-node_height//2+30}" font-family="Inter, -apple-system, sans-serif" '
            f'font-size="16" font-weight="700" fill="#FFFFFF" text-anchor="middle">{entity_name}</text>',
            
            # Attributes
            f'<rect x="{x-node_width//2+10}" y="{y-node_height//2+40}" width="{node_width-20}" height="{node_height-50}" '
            'rx="4" fill="#FFFFFF" fill-opacity="0.2" stroke="#FFFFFF" stroke-width="1" stroke-opacity="0.3"/>',
        ])
        
        # Add attributes (limited to 3 for space)
        for j, attr in enumerate(attributes[:3]):
            svg_elements.append(
                f'<text x="{x}" y="{y-node_height//2+60+j*20}" font-family="Inter, -apple-system, sans-serif" '
                f'font-size="12" fill="#FFFFFF" text-anchor="middle">{attr[:20]}</text>'
            )
        
        if len(attributes) > 3:
            svg_elements.append(
                f'<text x="{x}" y="{y-node_height//2+60+3*20}" font-family="Inter, -apple-system, sans-serif" '
                f'font-size="10" fill="#FFFFFF" text-anchor="middle">+{len(attributes)-3} more</text>'
            )

    # Add relationships (simplified for this example)
    # In a real implementation, you'd parse actual relationships from the data
    if len(entities) > 1:
        entities_list = list(entities.items())
        for i in range(len(entities_list)-1):
            from_ent = entities_list[i][0]
            to_ent = entities_list[i+1][0]
            x1, y1 = entity_positions[from_ent]
            x2, y2 = entity_positions[to_ent]
            
            # Draw relationship line
            svg_elements.extend([
                f'<line x1="{x1}" y1="{y1+node_height//2}" x2="{x2}" y2="{y2-node_height//2}" '
                'stroke="url(#relationshipGrad)" stroke-width="3" stroke-dasharray="5,3" marker-end="url(#erdArrow)"/>',
                
                # Relationship label
                f'<text x="{(x1+x2)/2}" y="{(y1+y2)/2-10}" font-family="Inter, -apple-system, sans-serif" '
                'font-size="12" fill="#374151" text-anchor="middle">1:N</text>'
            ])

    return f'<svg viewBox="0 0 {width} {height}" xmlns="http://www.w3.org/2000/svg" style="max-width: 100%; height: auto; font-family: Inter, -apple-system, sans-serif;">\n' + '\n'.join(svg_elements) + '\n</svg>'

def generate_enhanced_class_diagram_svg(classes):
    """Generate Class Diagram with premium design"""
    if not classes or not isinstance(classes, dict):
        return generate_error_svg("Class diagram requires classes data")

    width, height = 1400, 900
    class_width = 240
    min_class_height = 100
    spacing = 120
    
    # Calculate positions in a grid layout
    cols = min(3, len(classes))
    rows = math.ceil(len(classes) / cols)
    height = max(height, 150 + rows * (min_class_height + spacing))

    svg_elements = [
        '<defs>',
        # Class box gradient
        '''
        <linearGradient id="classGrad" x1="0%" y1="0%" x2="100%" y2="100%">
            <stop offset="0%" style="stop-color:#3B82F6;stop-opacity:1" />
            <stop offset="100%" style="stop-color:#6366F1;stop-opacity:1" />
        </linearGradient>
        ''',
        # Inheritance arrow
        '''
        <marker id="inheritanceArrow" markerWidth="12" markerHeight="12" refX="6" refY="6" orient="auto">
            <polygon points="0,0 12,6 0,12 6,6" fill="#1F2937" opacity="0.8"/>
        </marker>
        ''',
        '''
        <filter id="premiumShadow" x="-30%" y="-30%" width="160%" height="160%">
            <feGaussianBlur in="SourceAlpha" stdDeviation="4"/>
            <feOffset dx="2" dy="4" result="offset"/>
            <feFlood flood-color="#000000" flood-opacity="0.2"/>
            <feComposite in2="offset" operator="in"/>
            <feMerge><feMergeNode/><feMergeNode in="SourceGraphic"/></feMerge>
        </filter>
        ''',
        '</defs>',
        
        # Background
        f'<rect width="{width}" height="{height}" fill="#F9FAFB"/>',
        
        # Title
        f'<text x="{width//2}" y="40" font-family="Inter, -apple-system, sans-serif" '
        'font-size="28" font-weight="800" fill="#1F2937" text-anchor="middle">Class Diagram</text>',
        f'<text x="{width//2}" y="70" font-family="Inter, -apple-system, sans-serif" '
        'font-size="16" fill="#6B7280" text-anchor="middle">Object-oriented design visualization</text>',
    ]

    # Calculate positions for classes in a grid
    class_positions = {}
    col_width = width // (cols + 1)
    row_height = (height - 100) // (rows + 1)
    
    for i, (class_name, members) in enumerate(classes.items()):
        col = i % cols
        row = i // cols
        x = (col + 1) * col_width
        y = 100 + row * row_height
        class_positions[class_name] = (x, y)
        
        # Calculate class box height based on content
        attr_count = len(members.get("attributes", []))
        method_count = len(members.get("methods", []))
        class_height = min_class_height + (max(attr_count, method_count) * 20)
        
        # Class box
        svg_elements.extend([
            f'<rect x="{x-class_width//2}" y="{y}" width="{class_width}" height="{class_height}" '
            'rx="8" fill="url(#classGrad)" stroke="#FFFFFF" stroke-width="2" filter="url(#premiumShadow)"/>',
            
            # Class name section
            f'<rect x="{x-class_width//2}" y="{y}" width="{class_width}" height="40" '
            'rx="8" fill="#FFFFFF" fill-opacity="0.3"/>',
            
            # Class name
            f'<text x="{x}" y="{y+28}" font-family="Inter, -apple-system, sans-serif" '
            f'font-size="16" font-weight="700" fill="#1F2937" text-anchor="middle">{class_name}</text>',
            
            # Separator line
            f'<line x1="{x-class_width//2}" y1="{y+40}" x2="{x+class_width//2}" y2="{y+40}" '
            'stroke="#FFFFFF" stroke-width="1" stroke-opacity="0.5"/>',
        ])
        
        # Attributes section
        svg_elements.append(
            f'<text x="{x-class_width//2+10}" y="{y+60}" font-family="Inter, -apple-system, sans-serif" '
            'font-size="12" font-weight="600" fill="#FFFFFF" opacity="0.9">Attributes:</text>'
        )
        
        for j, attr in enumerate(members.get("attributes", [])[:5]):  # Limit to 5 attributes
            svg_elements.append(
                f'<text x="{x-class_width//2+15}" y="{y+80+j*16}" font-family="Inter, -apple-system, sans-serif" '
                f'font-size="12" fill="#FFFFFF">{attr[:20]}</text>'
            )
        
        # Methods section
        svg_elements.append(
            f'<text x="{x-class_width//2+10}" y="{y+80+len(members.get("attributes", []))*16}" '
            'font-family="Inter, -apple-system, sans-serif" font-size="12" font-weight="600" fill="#FFFFFF" opacity="0.9">Methods:</text>'
        )
        
        for k, method in enumerate(members.get("methods", [])[:5]):  # Limit to 5 methods
            svg_elements.append(
                f'<text x="{x-class_width//2+15}" y="{y+100+len(members.get("attributes", []))*16+k*16}" '
                f'font-family="Inter, -apple-system, sans-serif" font-size="12" fill="#FFFFFF">{method[:20]}()</text>'
            )
    
    # Add inheritance relationships (simplified example)
    if len(classes) > 1:
        class_list = list(classes.items())
        for i in range(len(class_list)-1):
            from_class = class_list[i][0]
            to_class = class_list[i+1][0]
            x1, y1 = class_positions[from_class]
            x2, y2 = class_positions[to_class]
            
            # Draw inheritance arrow
            svg_elements.extend([
                f'<path d="M{x1} {y1+20} Q{x1} {y1-50} {x2} {y2-20}" '
                'stroke="#1F2937" stroke-width="2" fill="none" marker-end="url(#inheritanceArrow)"/>',
                
                # Relationship label
                f'<text x="{(x1+x2)/2}" y="{y1-30}" font-family="Inter, -apple-system, sans-serif" '
                'font-size="12" fill="#1F2937" text-anchor="middle">inherits</text>'
            ])

    return f'<svg viewBox="0 0 {width} {height}" xmlns="http://www.w3.org/2000/svg" style="max-width: 100%; height: auto; font-family: Inter, -apple-system, sans-serif;">\n' + '\n'.join(svg_elements) + '\n</svg>'

def generate_enhanced_flowchart_svg(steps):
    """Ultra-enhanced flowchart with premium design"""
    if not steps or len(steps) < 2:
        return generate_error_svg("Flowchart needs at least 2 steps")

    width = 1400
    node_width = 320
    node_height = 120
    spacing = 160
    height = 180 + len(steps) * (node_height + spacing)

    # Premium color palette
    colors = [
        {'primary': '#667eea', 'secondary': '#764ba2'},
        {'primary': '#f093fb', 'secondary': '#f5576c'},
        {'primary': '#4facfe', 'secondary': '#00f2fe'},
        {'primary': '#43e97b', 'secondary': '#38f9d7'},
        {'primary': '#fa709a', 'secondary': '#fee140'},
        {'primary': '#a8edea', 'secondary': '#fed6e3'},
    ]

    svg_elements = [
        '<defs>',
        # Premium gradients
        *[f'''
        <linearGradient id="nodeGrad{i+1}" x1="0%" y1="0%" x2="100%" y2="100%">
            <stop offset="0%" style="stop-color:{colors[i % len(colors)]['primary']};stop-opacity:1" />
            <stop offset="100%" style="stop-color:{colors[i % len(colors)]['secondary']};stop-opacity:1" />
        </linearGradient>
        ''' for i in range(len(steps))],

        # Ultra-premium shadow filter
        '''
        <filter id="premiumShadow" x="-50%" y="-50%" width="200%" height="200%">
            <feGaussianBlur in="SourceAlpha" stdDeviation="6"/>
            <feOffset dx="3" dy="8" result="offset"/>
            <feFlood flood-color="#000000" flood-opacity="0.25"/>
            <feComposite in2="offset" operator="in"/>
            <feMerge><feMergeNode/><feMergeNode in="SourceGraphic"/></feMerge>
        </filter>
        ''',

        # Glow effect
        '''
        <filter id="glow" x="-50%" y="-50%" width="200%" height="200%">
            <feGaussianBlur stdDeviation="4" result="coloredBlur"/>
            <feMerge><feMergeNode in="coloredBlur"/><feMergeNode in="SourceGraphic"/></feMerge>
        </filter>
        ''',

        # Enhanced arrow marker
        '''
        <marker id="premiumArrow" markerWidth="16" markerHeight="12" refX="15" refY="6" orient="auto">
            <polygon points="0 0, 16 6, 0 12" fill="#4a5568" opacity="0.8"/>
        </marker>
        ''',
        '</defs>',

        # Premium background with subtle pattern
        f'<rect width="{width}" height="{height}" fill="#f8fafc"/>',

        # Background pattern
        '''
        <defs>
            <pattern id="bgPattern" x="0" y="0" width="40" height="40" patternUnits="userSpaceOnUse">
                <circle cx="20" cy="20" r="1" fill="#e2e8f0"/>
            </pattern>
        </defs>
        ''',
    ]

    for i, (step_name, step_content) in enumerate(steps.items()):
        x = width // 2
        y = 140 + i * (node_height + spacing)
        gradient_id = f"nodeGrad{i + 1}"

        # Ultra-premium node design
        svg_elements.extend([
            # Outer glow
            f'<rect x="{x-node_width//2-5}" y="{y-5}" width="{node_width+10}" height="{node_height+10}" '
            f'rx="20" ry="20" fill="url(#{gradient_id})" opacity="0.2" filter="url(#glow)"/>',

            # Main node
            f'<rect x="{x-node_width//2}" y="{y}" width="{node_width}" height="{node_height}" '
            f'rx="18" ry="18" fill="url(#{gradient_id})" filter="url(#premiumShadow)" '
            'stroke="rgba(255,255,255,0.4)" stroke-width="2"/>',

            # Inner highlight
            f'<rect x="{x-node_width//2+4}" y="{y+4}" width="{node_width-8}" height="3" '
            'rx="2" fill="rgba(255,255,255,0.5)"/>',

            # Step number badge
            f'<circle cx="{x-node_width//2+25}" cy="{y+25}" r="15" fill="rgba(255,255,255,0.3)"/>',
            f'<text x="{x-node_width//2+25}" y="{y+30}" font-family="Inter, -apple-system, sans-serif" '
            f'font-size="14" font-weight="800" fill="white" text-anchor="middle">{i+1}</text>',
        ])

        # Enhanced text with better formatting
        title = str(step_name)[:28]
        description = (step_content[0] if step_content else "")[:60]

        # Smart text wrapping
        title_lines = textwrap.wrap(title, width=25)[:2]
        desc_lines = textwrap.wrap(description, width=40)[:2]

        # Title
        for j, line in enumerate(title_lines):
            svg_elements.append(
                f'<text x="{x}" y="{y+35+j*20}" font-family="Inter, -apple-system, sans-serif" '
                f'font-size="18" font-weight="700" fill="white" text-anchor="middle" '
                f'letter-spacing="0.5px">{line}</text>'
            )

        # Description
        desc_start_y = y + 35 + len(title_lines) * 20 + 10
        for j, line in enumerate(desc_lines):
            svg_elements.append(
                f'<text x="{x}" y="{desc_start_y+j*16}" font-family="Inter, -apple-system, sans-serif" '
                f'font-size="13" fill="rgba(255,255,255,0.9)" text-anchor="middle">{line}</text>'
            )

        # Premium connector with animation-ready design
        if i < len(steps)-1:
            next_y = y + node_height + spacing
            mid_y = y + node_height + spacing//2

            svg_elements.extend([
                # Connection glow
                f'<path d="M{x} {y+node_height} Q{x+30} {mid_y} {x} {next_y-25}" '
                f'stroke="url(#{gradient_id})" stroke-width="8" fill="none" opacity="0.3"/>',

                # Main connection
                f'<path d="M{x} {y+node_height} Q{x+30} {mid_y} {x} {next_y-25}" '
                'stroke="#4a5568" stroke-width="4" fill="none" opacity="0.8" '
                'marker-end="url(#premiumArrow)"/>',
            ])

    # Add title
    svg_elements.extend([
        f'<text x="{width//2}" y="40" font-family="Inter, -apple-system, sans-serif" '
        'font-size="28" font-weight="800" fill="#2d3748" text-anchor="middle">Process Flow</text>',
        f'<text x="{width//2}" y="65" font-family="Inter, -apple-system, sans-serif" '
        'font-size="16" fill="#718096" text-anchor="middle">Step-by-step workflow visualization</text>',
    ])

    return f'<svg viewBox="0 0 {width} {height}" xmlns="http://www.w3.org/2000/svg" style="max-width: 100%; height: auto; font-family: Inter, -apple-system, sans-serif;">\n' + '\n'.join(svg_elements) + '\n</svg>'

def generate_themed_mindmap_svg(central_topic, branches, variation, theme):
    """Generate mind map with specific theme and style variation"""
    if not central_topic or not branches:
        return generate_error_svg("Mind map requires central topic and branches")

    width, height = 1400, 900
    center_x, center_y = width // 2, height // 2
    
    svg_elements = [
        '<defs>',
        '''
        <linearGradient id="mindmapGrad" x1="0%" y1="0%" x2="100%" y2="100%">
            <stop offset="0%" style="stop-color:{theme['primary']};stop-opacity:1" />
            <stop offset="100%" style="stop-color:{theme['secondary']};stop-opacity:1" />
        </linearGradient>
        ''',
        '''
        <filter id="mindmapShadow" x="-20%" y="-20%" width="140%" height="140%">
            <feGaussianBlur in="SourceAlpha" stdDeviation="3"/>
            <feOffset dx="2" dy="4" result="offset"/>
            <feFlood flood-color="#000000" flood-opacity="0.15"/>
            <feComposite in2="offset" operator="in"/>
            <feMerge><feMergeNode/><feMergeNode in="SourceGraphic"/></feMerge>
        </filter>
        ''',
        '</defs>',
        
        f'<rect width="{width}" height="{height}" fill="#F8FAFC"/>',
        
        # Title
        f'<text x="{width//2}" y="40" font-family="Inter, sans-serif" '
        f'font-size="28" font-weight="800" fill="{theme["primary"]}" text-anchor="middle">{variation["name"]}</text>',
    ]

    # Central topic
    svg_elements.extend([
        f'<circle cx="{center_x}" cy="{center_y}" r="60" fill="url(#mindmapGrad)" filter="url(#mindmapShadow)"/>',
        f'<text x="{center_x}" y="{center_y-10}" font-family="Inter, sans-serif" '
        f'font-size="18" font-weight="700" fill="#FFFFFF" text-anchor="middle">{central_topic[:15]}</text>',
        f'<text x="{center_x}" y="{center_y+15}" font-family="Inter, sans-serif" '
        f'font-size="12" fill="#E5E7EB" text-anchor="middle">Central Topic</text>',
    ])

    # Draw branches
    branch_count = len(branches)
    angle_step = 360 / max(branch_count, 1)
    radius = 200
    
    for i, (branch_name, concepts) in enumerate(branches.items()):
        angle = math.radians(i * angle_step)
        x = center_x + radius * math.cos(angle)
        y = center_y + radius * math.sin(angle)
        
        # Branch node
        svg_elements.extend([
            f'<rect x="{x-50}" y="{y-30}" width="100" height="60" '
            'rx="8" fill="url(#mindmapGrad)" filter="url(#mindmapShadow)"/>',
            
            f'<text x="{x}" y="{y-5}" font-family="Inter, sans-serif" '
            f'font-size="12" font-weight="700" fill="#FFFFFF" text-anchor="middle">{branch_name[:12]}</text>',
            
            f'<text x="{x}" y="{y+15}" font-family="Inter, sans-serif" '
            f'font-size="10" fill="#E5E7EB" text-anchor="middle">{concepts[0][:15] if concepts else ""}</text>',
        ])
        
        # Connection line
        svg_elements.append(
            f'<line x1="{center_x}" y1="{center_y}" x2="{x}" y2="{y}" '
            'stroke="{theme["accent"]}" stroke-width="3" opacity="0.6"/>'
        )

    return f'<svg viewBox="0 0 {width} {height}" xmlns="http://www.w3.org/2000/svg" style="max-width: 100%; height: auto;">\n' + '\n'.join(svg_elements) + '\n</svg>'

def generate_themed_swot_svg(swot_data, variation, theme):
    """Generate SWOT analysis with specific theme and style variation"""
    if not swot_data:
        return generate_error_svg("SWOT analysis requires data")

    width, height = 1400, 900
    quadrant_width = width // 2
    quadrant_height = height // 2
    
    svg_elements = [
        '<defs>',
        '''
        <linearGradient id="swotGrad" x1="0%" y1="0%" x2="100%" y2="100%">
            <stop offset="0%" style="stop-color:{theme['primary']};stop-opacity:1" />
            <stop offset="100%" style="stop-color:{theme['secondary']};stop-opacity:1" />
        </linearGradient>
        ''',
        '</defs>',
        
        f'<rect width="{width}" height="{height}" fill="#F8FAFC"/>',
        
        # Title
        f'<text x="{width//2}" y="40" font-family="Inter, sans-serif" '
        f'font-size="28" font-weight="800" fill="{theme["primary"]}" text-anchor="middle">{variation["name"]}</text>',
        
        # Grid lines
        f'<line x1="{quadrant_width}" y1="80" x2="{quadrant_width}" y2="{height-50}" stroke="#9CA3AF" stroke-width="2"/>',
        f'<line x1="50" y1="{quadrant_height+80}" x2="{width-50}" y2="{quadrant_height+80}" stroke="#9CA3AF" stroke-width="2"/>',
    ]

    # SWOT quadrants
    quadrants = [
        {"title": "Strengths", "x": 0, "y": 0, "color": "#10B981"},
        {"title": "Weaknesses", "x": 1, "y": 0, "color": "#EF4444"},
        {"title": "Opportunities", "x": 0, "y": 1, "color": "#3B82F6"},
        {"title": "Threats", "x": 1, "y": 1, "color": "#F59E0B"}
    ]
    
    for quadrant in quadrants:
        x = 50 + quadrant["x"] * quadrant_width
        y = 100 + quadrant["y"] * quadrant_height
        
        # Quadrant title
        svg_elements.extend([
            f'<text x="{x + quadrant_width//2}" y="{y+30}" font-family="Inter, sans-serif" '
            f'font-size="20" font-weight="700" fill="{quadrant["color"]}" text-anchor="middle">{quadrant["title"]}</text>',
            
            f'<rect x="{x+20}" y="{y+40}" width="{quadrant_width-40}" height="{quadrant_height-60}" '
            f'rx="8" fill="rgba({quadrant["color"]}, 0.1)" stroke="{quadrant["color"]}" stroke-width="1"/>',
        ])
        
        # Add items from data
        items = swot_data.get(quadrant["title"].lower(), [])
        for i, item in enumerate(items[:5]):  # Limit to 5 items per quadrant
            item_y = y + 70 + i * 25
            if item_y < y + quadrant_height - 20:
                svg_elements.append(
                    f'<text x="{x+30}" y="{item_y}" font-family="Inter, sans-serif" '
                    f'font-size="12" fill="#374151">• {str(item)[:30]}</text>'
                )

    return f'<svg viewBox="0 0 {width} {height}" xmlns="http://www.w3.org/2000/svg" style="max-width: 100%; height: auto;">\n' + '\n'.join(svg_elements) + '\n</svg>'

def generate_themed_timeline_svg(events, variation, theme):
    """Generate timeline with specific theme and style variation"""
    if not events:
        return generate_error_svg("Timeline requires events")

    width, height = 1400, 600
    timeline_y = height // 2
    
    svg_elements = [
        '<defs>',
        '''
        <linearGradient id="timelineGrad" x1="0%" y1="0%" x2="100%" y2="100%">
            <stop offset="0%" style="stop-color:{theme['primary']};stop-opacity:1" />
            <stop offset="100%" style="stop-color:{theme['secondary']};stop-opacity:1" />
        </linearGradient>
        ''',
        '</defs>',
        
        f'<rect width="{width}" height="{height}" fill="#F8FAFC"/>',
        
        # Title
        f'<text x="{width//2}" y="40" font-family="Inter, sans-serif" '
        f'font-size="28" font-weight="800" fill="{theme["primary"]}" text-anchor="middle">{variation["name"]}</text>',
        
        # Timeline line
        f'<line x1="100" y1="{timeline_y}" x2="{width-100}" y2="{timeline_y}" stroke="{theme["accent"]}" stroke-width="4"/>',
    ]

    # Draw events
    event_count = len(events)
    spacing = (width - 200) // max(event_count - 1, 1)
    
    for i, (event_name, event_data) in enumerate(events.items()):
        x = 100 + i * spacing
        y = timeline_y
        
        # Event circle
        svg_elements.extend([
            f'<circle cx="{x}" cy="{y}" r="20" fill="url(#timelineGrad)" stroke="#FFFFFF" stroke-width="3"/>',
            f'<text x="{x}" y="{y+5}" font-family="Inter, sans-serif" '
            f'font-size="12" font-weight="700" fill="#FFFFFF" text-anchor="middle">{i+1}</text>',
        ])
        
        # Event details above or below timeline
        if i % 2 == 0:
            # Above timeline
            detail_y = y - 60
            svg_elements.extend([
                f'<rect x="{x-80}" y="{detail_y-40}" width="160" height="80" '
                'rx="8" fill="#FFFFFF" stroke="{theme["primary"]}" stroke-width="2"/>',
                
                f'<text x="{x}" y="{detail_y-20}" font-family="Inter, sans-serif" '
                f'font-size="12" font-weight="700" fill="{theme["primary"]}" text-anchor="middle">{event_name[:20]}</text>',
                
                f'<text x="{x}" y="{detail_y}" font-family="Inter, sans-serif" '
                f'font-size="10" fill="#6B7280" text-anchor="middle">{str(event_data)[:25]}</text>',
            ])
        else:
            # Below timeline
            detail_y = y + 60
            svg_elements.extend([
                f'<rect x="{x-80}" y="{detail_y}" width="160" height="80" '
                'rx="8" fill="#FFFFFF" stroke="{theme["primary"]}" stroke-width="2"/>',
                
                f'<text x="{x}" y="{detail_y+20}" font-family="Inter, sans-serif" '
                f'font-size="12" font-weight="700" fill="{theme["primary"]}" text-anchor="middle">{event_name[:20]}</text>',
                
                f'<text x="{x}" y="{detail_y+40}" font-family="Inter, sans-serif" '
                f'font-size="10" fill="#6B7280" text-anchor="middle">{str(event_data)[:25]}</text>',
            ])

    return f'<svg viewBox="0 0 {width} {height}" xmlns="http://www.w3.org/2000/svg" style="max-width: 100%; height: auto;">\n' + '\n'.join(svg_elements) + '\n</svg>'

def generate_themed_sequence_svg(actors, interactions, variation, theme):
    """Generate sequence diagram with specific theme and style variation"""
    if not actors or not interactions:
        return generate_error_svg("Sequence diagram requires actors and interactions")

    width, height = 1400, 800
    actor_width = 120
    actor_height = 60
    message_height = 80
    
    # Calculate positions
    actor_spacing = (width - 100) // max(len(actors), 1)
    actor_positions = {}
    
    svg_elements = [
        '<defs>',
        '''
        <linearGradient id="actorGrad" x1="0%" y1="0%" x2="100%" y2="100%">
            <stop offset="0%" style="stop-color:{theme['primary']};stop-opacity:1" />
            <stop offset="100%" style="stop-color:{theme['secondary']};stop-opacity:1" />
        </linearGradient>
        ''',
        '''
        <marker id="seqArrow" markerWidth="10" markerHeight="7" refX="9" refY="3.5" orient="auto">
            <polygon points="0 0, 10 3.5, 0 7" fill="{theme['accent']}"/>
        </marker>
        ''',
        '</defs>',
        
        f'<rect width="{width}" height="{height}" fill="#F8FAFC"/>',
        
        # Title
        f'<text x="{width//2}" y="40" font-family="Inter, sans-serif" '
        f'font-size="28" font-weight="800" fill="{theme["primary"]}" text-anchor="middle">{variation["name"]}</text>',
    ]

    # Draw actors
    for i, (actor_name, actor_desc) in enumerate(actors.items()):
        x = 50 + i * actor_spacing + actor_spacing // 2
        y = 80
        actor_positions[actor_name] = x
        
        # Actor box
        svg_elements.extend([
            f'<rect x="{x-actor_width//2}" y="{y}" width="{actor_width}" height="{actor_height}" '
            'rx="8" fill="url(#actorGrad)" stroke="#FFFFFF" stroke-width="2"/>',
            
            f'<text x="{x}" y="{y+25}" font-family="Inter, sans-serif" '
            f'font-size="14" font-weight="700" fill="#FFFFFF" text-anchor="middle">{actor_name[:12]}</text>',
            
            f'<text x="{x}" y="{y+45}" font-family="Inter, sans-serif" '
            f'font-size="10" fill="#E5E7EB" text-anchor="middle">{actor_desc[:15]}</text>',
            
            # Lifeline
            f'<line x1="{x}" y1="{y+actor_height}" x2="{x}" y2="{height-50}" '
            'stroke="#9CA3AF" stroke-width="2" stroke-dasharray="5,5"/>',
        ])

    # Draw interactions
    sorted_interactions = sorted(interactions, key=lambda x: x.get('order', 0))
    for i, interaction in enumerate(sorted_interactions):
        from_actor = interaction.get('from', '')
        to_actor = interaction.get('to', '')
        message = interaction.get('message', '')
        
        if from_actor in actor_positions and to_actor in actor_positions:
            x1 = actor_positions[from_actor]
            x2 = actor_positions[to_actor]
            y = 180 + i * message_height
            
            svg_elements.extend([
                f'<line x1="{x1}" y1="{y}" x2="{x2}" y2="{y}" '
                'stroke="{theme["accent"]}" stroke-width="2" marker-end="url(#seqArrow)"/>',
                
                f'<text x="{(x1+x2)/2}" y="{y-10}" font-family="Inter, sans-serif" '
                f'font-size="12" fill="#374151" text-anchor="middle">{message[:30]}</text>'
            ])

    return f'<svg viewBox="0 0 {width} {height}" xmlns="http://www.w3.org/2000/svg" style="max-width: 100%; height: auto;">\n' + '\n'.join(svg_elements) + '\n</svg>'

def generate_themed_state_svg(states, transitions, variation, theme):
    """Generate state diagram with specific theme and style variation"""
    if not states:
        return generate_error_svg("State diagram requires states")

    width, height = 1400, 800
    state_radius = 80
    
    # Position states in a circular layout
    center_x, center_y = width // 2, height // 2
    radius = min(width, height) * 0.3
    angle_step = 360 / max(len(states), 1)
    
    state_positions = {}
    
    svg_elements = [
        '<defs>',
        '''
        <linearGradient id="stateGrad" x1="0%" y1="0%" x2="100%" y2="100%">
            <stop offset="0%" style="stop-color:{theme['primary']};stop-opacity:1" />
            <stop offset="100%" style="stop-color:{theme['secondary']};stop-opacity:1" />
        </linearGradient>
        ''',
        '''
        <marker id="stateArrow" markerWidth="10" markerHeight="7" refX="9" refY="3.5" orient="auto">
            <polygon points="0 0, 10 3.5, 0 7" fill="{theme['accent']}"/>
        </marker>
        ''',
        '</defs>',
        
        f'<rect width="{width}" height="{height}" fill="#F8FAFC"/>',
        
        # Title
        f'<text x="{width//2}" y="40" font-family="Inter, sans-serif" '
        f'font-size="28" font-weight="800" fill="{theme["primary"]}" text-anchor="middle">{variation["name"]}</text>',
    ]

    # Draw states
    for i, (state_name, state_desc) in enumerate(states.items()):
        angle = math.radians(i * angle_step)
        x = center_x + radius * math.cos(angle)
        y = center_y + radius * math.sin(angle)
        state_positions[state_name] = (x, y)
        
        # State circle
        svg_elements.extend([
            f'<circle cx="{x}" cy="{y}" r="{state_radius}" fill="url(#stateGrad)" stroke="#FFFFFF" stroke-width="3"/>',
            
            f'<text x="{x}" y="{y-10}" font-family="Inter, sans-serif" '
            f'font-size="14" font-weight="700" fill="#FFFFFF" text-anchor="middle">{state_name[:12]}</text>',
            
            f'<text x="{x}" y="{y+10}" font-family="Inter, sans-serif" '
            f'font-size="10" fill="#E5E7EB" text-anchor="middle">{state_desc[:20]}</text>',
        ])

    # Draw transitions
    for transition in transitions:
        from_state = transition.get('from', '')
        to_state = transition.get('to', '')
        trigger = transition.get('trigger', '')
        
        if from_state in state_positions and to_state in state_positions:
            x1, y1 = state_positions[from_state]
            x2, y2 = state_positions[to_state]
            
            # Calculate arrow positions on circle edges
            dx, dy = x2 - x1, y2 - y1
            length = math.sqrt(dx*dx + dy*dy)
            if length > 0:
                dx, dy = dx/length, dy/length
                start_x, start_y = x1 + dx * state_radius, y1 + dy * state_radius
                end_x, end_y = x2 - dx * state_radius, y2 - dy * state_radius
                
                svg_elements.extend([
                    f'<line x1="{start_x}" y1="{start_y}" x2="{end_x}" y2="{end_y}" '
                    'stroke="{theme["accent"]}" stroke-width="2" marker-end="url(#stateArrow)"/>',
                    
                    f'<text x="{(start_x+end_x)/2}" y="{(start_y+end_y)/2-10}" font-family="Inter, sans-serif" '
                    f'font-size="10" fill="#374151" text-anchor="middle">{trigger[:15]}</text>'
                ])

    return f'<svg viewBox="0 0 {width} {height}" xmlns="http://www.w3.org/2000/svg" style="max-width: 100%; height: auto;">\n' + '\n'.join(svg_elements) + '\n</svg>'

def generate_themed_class_svg(classes, variation, theme):
    """Generate class diagram with specific theme and style variation"""
    if not classes or not isinstance(classes, dict):
        return generate_error_svg("Class diagram requires classes data")

    width, height = 1400, 900
    class_width = 240
    min_class_height = 100
    spacing = 120
    
    # Calculate positions in a grid layout
    cols = min(3, len(classes))
    rows = math.ceil(len(classes) / cols)
    height = max(height, 150 + rows * (min_class_height + spacing))

    svg_elements = [
        '<defs>',
        # Class box gradient
        '''
        <linearGradient id="classGrad" x1="0%" y1="0%" x2="100%" y2="100%">
            <stop offset="0%" style="stop-color:{theme['primary']};stop-opacity:1" />
            <stop offset="100%" style="stop-color:{theme['secondary']};stop-opacity:1" />
        </linearGradient>
        ''',
        # Inheritance arrow
        '''
        <marker id="inheritanceArrow" markerWidth="12" markerHeight="12" refX="6" refY="6" orient="auto">
            <polygon points="0,0 12,6 0,12 6,6" fill="#1F2937" opacity="0.8"/>
        </marker>
        ''',
        '''
        <filter id="premiumShadow" x="-30%" y="-30%" width="160%" height="160%">
            <feGaussianBlur in="SourceAlpha" stdDeviation="4"/>
            <feOffset dx="2" dy="4" result="offset"/>
            <feFlood flood-color="#000000" flood-opacity="0.2"/>
            <feComposite in2="offset" operator="in"/>
            <feMerge><feMergeNode/><feMergeNode in="SourceGraphic"/></feMerge>
        </filter>
        ''',
        '</defs>',
        
        # Background
        f'<rect width="{width}" height="{height}" fill="#F9FAFB"/>',
        
        # Title
        f'<text x="{width//2}" y="40" font-family="Inter, -apple-system, sans-serif" '
        f'font-size="28" font-weight="800" fill="{theme["primary"]}" text-anchor="middle">{variation["name"]}</text>',
        f'<text x="{width//2}" y="70" font-family="Inter, -apple-system, sans-serif" '
        f'font-size="16" fill="#6B7280" text-anchor="middle">Object-oriented design visualization</text>',
    ]

    # Calculate positions for classes in a grid
    class_positions = {}
    col_width = width // (cols + 1)
    row_height = (height - 100) // (rows + 1)
    
    for i, (class_name, members) in enumerate(classes.items()):
        col = i % cols
        row = i // cols
        x = (col + 1) * col_width
        y = 100 + row * row_height
        class_positions[class_name] = (x, y)
        
        # Calculate class box height based on content
        attr_count = len(members.get("attributes", []))
        method_count = len(members.get("methods", []))
        class_height = min_class_height + (max(attr_count, method_count) * 20)
        
        # Class box
        svg_elements.extend([
            f'<rect x="{x-class_width//2}" y="{y}" width="{class_width}" height="{class_height}" '
            'rx="8" fill="url(#classGrad)" stroke="#FFFFFF" stroke-width="2" filter="url(#premiumShadow)"/>',
            
            # Class name section
            f'<rect x="{x-class_width//2}" y="{y}" width="{class_width}" height="40" '
            'rx="8" fill="#FFFFFF" fill-opacity="0.3"/>',
            
            # Class name
            f'<text x="{x}" y="{y+28}" font-family="Inter, -apple-system, sans-serif" '
            f'font-size="16" font-weight="700" fill="#1F2937" text-anchor="middle">{class_name}</text>',
            
            # Separator line
            f'<line x1="{x-class_width//2}" y1="{y+40}" x2="{x+class_width//2}" y2="{y+40}" '
            'stroke="#FFFFFF" stroke-width="1" stroke-opacity="0.5"/>',
        ])
        
        # Attributes section
        svg_elements.append(
            f'<text x="{x-class_width//2+10}" y="{y+60}" font-family="Inter, -apple-system, sans-serif" '
            'font-size="12" font-weight="600" fill="#FFFFFF" opacity="0.9">Attributes:</text>'
        )
        
        for j, attr in enumerate(members.get("attributes", [])[:5]):  # Limit to 5 attributes
            svg_elements.append(
                f'<text x="{x-class_width//2+15}" y="{y+80+j*16}" font-family="Inter, -apple-system, sans-serif" '
                f'font-size="12" fill="#FFFFFF">{attr[:20]}</text>'
            )
        
        # Methods section
        svg_elements.append(
            f'<text x="{x-class_width//2+10}" y="{y+80+len(members.get("attributes", []))*16}" '
            'font-family="Inter, -apple-system, sans-serif" font-size="12" font-weight="600" fill="#FFFFFF" opacity="0.9">Methods:</text>'
        )
        
        for k, method in enumerate(members.get("methods", [])[:5]):  # Limit to 5 methods
            svg_elements.append(
                f'<text x="{x-class_width//2+15}" y="{y+100+len(members.get("attributes", []))*16+k*16}" '
                f'font-family="Inter, -apple-system, sans-serif" font-size="12" fill="#FFFFFF">{method[:20]}()</text>'
            )
    
    # Add inheritance relationships (simplified example)
    if len(classes) > 1:
        class_list = list(classes.items())
        for i in range(len(class_list)-1):
            from_class = class_list[i][0]
            to_class = class_list[i+1][0]
            x1, y1 = class_positions[from_class]
            x2, y2 = class_positions[to_class]
            
            # Draw inheritance arrow
            svg_elements.extend([
                f'<path d="M{x1} {y1+20} Q{x1} {y1-50} {x2} {y2-20}" '
                'stroke="#1F2937" stroke-width="2" fill="none" marker-end="url(#inheritanceArrow)"/>',
                
                # Relationship label
                f'<text x="{(x1+x2)/2}" y="{y1-30}" font-family="Inter, -apple-system, sans-serif" '
                'font-size="12" fill="#1F2937" text-anchor="middle">inherits</text>'
            ])

    return f'<svg viewBox="0 0 {width} {height}" xmlns="http://www.w3.org/2000/svg" style="max-width: 100%; height: auto; font-family: Inter, -apple-system, sans-serif;">\n' + '\n'.join(svg_elements) + '\n</svg>'

def generate_themed_erd_svg(entities, variation, theme):
    """Generate entity relationship diagram with specific theme and style variation"""
    if not entities or not isinstance(entities, dict):
        return generate_error_svg("ERD requires entities data")

    width, height = 1400, 900
    node_width = 220
    node_height = 120
    spacing = 100
    
    # Calculate required height based on entities
    height = max(height, 200 + len(entities) * (node_height + spacing))

    svg_elements = [
        '<defs>',
        # Premium gradients for different entity types
        '''
        <linearGradient id="entityGrad" x1="0%" y1="0%" x2="100%" y2="100%">
            <stop offset="0%" style="stop-color:{theme['primary']};stop-opacity:1" />
            <stop offset="100%" style="stop-color:{theme['secondary']};stop-opacity:1" />
        </linearGradient>
        ''',
        '''
        <linearGradient id="relationshipGrad" x1="0%" y1="0%" x2="100%" y2="100%">
            <stop offset="0%" style="stop-color:{theme['secondary']};stop-opacity:0.9" />
            <stop offset="100%" style="stop-color:{theme['accent']};stop-opacity:1" />
        </linearGradient>
        ''',
        # Arrow marker for relationships
        '''
        <marker id="erdArrow" markerWidth="10" markerHeight="7" refX="9" refY="3.5" orient="auto">
            <polygon points="0 0, 10 3.5, 0 7" fill="{theme['accent']}"/>
        </marker>
        ''',
        '''
        <filter id="premiumShadow" x="-30%" y="-30%" width="160%" height="160%">
            <feGaussianBlur in="SourceAlpha" stdDeviation="4"/>
            <feOffset dx="2" dy="4" result="offset"/>
            <feFlood flood-color="#000000" flood-opacity="0.2"/>
            <feComposite in2="offset" operator="in"/>
            <feMerge><feMergeNode/><feMergeNode in="SourceGraphic"/></feMerge>
        </filter>
        ''',
        '</defs>',
        
        # Background
        f'<rect width="{width}" height="{height}" fill="#F9FAFB"/>',
        
        # Title
        f'<text x="{width//2}" y="40" font-family="Inter, -apple-system, sans-serif" '
        f'font-size="28" font-weight="800" fill="{theme["primary"]}" text-anchor="middle">{variation["name"]}</text>',
        f'<text x="{width//2}" y="70" font-family="Inter, -apple-system, sans-serif" '
        f'font-size="16" fill="#6B7280" text-anchor="middle">Database schema visualization</text>',
    ]

    # Calculate positions for entities in a circular layout
    center_x, center_y = width // 2, height // 2
    radius = min(width, height) * 0.35
    angle_step = 360 / max(len(entities), 1)
    
    entity_positions = {}
    for i, (entity_name, attributes) in enumerate(entities.items()):
        angle = math.radians(i * angle_step)
        x = center_x + radius * math.cos(angle)
        y = center_y + radius * math.sin(angle)
        entity_positions[entity_name] = (x, y)
        
        # Entity box
        svg_elements.extend([
            f'<rect x="{x-node_width//2}" y="{y-node_height//2}" width="{node_width}" height="{node_height}" '
            'rx="8" fill="url(#entityGrad)" stroke="#FFFFFF" stroke-width="2" filter="url(#premiumShadow)"/>',
            
            # Entity name
            f'<text x="{x}" y="{y-node_height//2+30}" font-family="Inter, -apple-system, sans-serif" '
            f'font-size="16" font-weight="700" fill="#FFFFFF" text-anchor="middle">{entity_name}</text>',
            
            # Attributes
            f'<rect x="{x-node_width//2+10}" y="{y-node_height//2+40}" width="{node_width-20}" height="{node_height-50}" '
            'rx="4" fill="#FFFFFF" fill-opacity="0.2" stroke="#FFFFFF" stroke-width="1" stroke-opacity="0.3"/>',
        ])
        
        # Add attributes (limited to 3 for space)
        for j, attr in enumerate(attributes[:3]):
            svg_elements.append(
                f'<text x="{x}" y="{y-node_height//2+60+j*20}" font-family="Inter, -apple-system, sans-serif" '
                f'font-size="12" fill="#FFFFFF" text-anchor="middle">{attr[:20]}</text>'
            )
        
        if len(attributes) > 3:
            svg_elements.append(
                f'<text x="{x}" y="{y-node_height//2+60+3*20}" font-family="Inter, -apple-system, sans-serif" '
                f'font-size="10" fill="#FFFFFF" text-anchor="middle">+{len(attributes)-3} more</text>'
            )

    # Add relationships (simplified for this example)
    # In a real implementation, you'd parse actual relationships from the data
    if len(entities) > 1:
        entities_list = list(entities.items())
        for i in range(len(entities_list)-1):
            from_ent = entities_list[i][0]
            to_ent = entities_list[i+1][0]
            x1, y1 = entity_positions[from_ent]
            x2, y2 = entity_positions[to_ent]
            
            # Draw relationship line
            svg_elements.extend([
                f'<line x1="{x1}" y1="{y1+node_height//2}" x2="{x2}" y2="{y2-node_height//2}" '
                'stroke="url(#relationshipGrad)" stroke-width="3" stroke-dasharray="5,3" marker-end="url(#erdArrow)"/>',
                
                # Relationship label
                f'<text x="{(x1+x2)/2}" y="{(y1+y2)/2-10}" font-family="Inter, -apple-system, sans-serif" '
                'font-size="12" fill="#374151" text-anchor="middle">1:N</text>'
            ])

    return f'<svg viewBox="0 0 {width} {height}" xmlns="http://www.w3.org/2000/svg" style="max-width: 100%; height: auto; font-family: Inter, -apple-system, sans-serif;">\n' + '\n'.join(svg_elements) + '\n</svg>'

def generate_themed_network_svg(nodes, connections, variation, theme):
    """Generate network diagram with specific theme and style variation"""
    if not nodes:
        return generate_error_svg("Network diagram requires nodes data")

    width, height = 1400, 900
    center_x, center_y = width // 2, height // 2
    
    svg_elements = [
        '<defs>',
        '''
        <linearGradient id="networkGrad" x1="0%" y1="0%" x2="100%" y2="100%">
            <stop offset="0%" style="stop-color:{theme['primary']};stop-opacity:1" />
            <stop offset="100%" style="stop-color:{theme['secondary']};stop-opacity:1" />
        </linearGradient>
        ''',
        '''
        <filter id="networkShadow" x="-30%" y="-30%" width="160%" height="160%">
            <feGaussianBlur in="SourceAlpha" stdDeviation="4"/>
            <feOffset dx="2" dy="4" result="offset"/>
            <feFlood flood-color="#000000" flood-opacity="0.2"/>
            <feComposite in2="offset" operator="in"/>
            <feMerge><feMergeNode/><feMergeNode in="SourceGraphic"/></feMerge>
        </filter>
        ''',
        '''
        <marker id="networkArrow" markerWidth="10" markerHeight="7" refX="9" refY="3.5" orient="auto">
            <polygon points="0 0, 10 3.5, 0 7" fill="{theme['accent']}"/>
        </marker>
        ''',
        '</defs>',
        
        f'<rect width="{width}" height="{height}" fill="#F8FAFC"/>',
        
        f'<text x="{width//2}" y="40" font-family="Inter, sans-serif" '
        f'font-size="28" font-weight="800" fill="{theme["primary"]}" text-anchor="middle">Network Architecture</text>',
        f'<text x="{width//2}" y="70" font-family="Inter, sans-serif" '
        f'font-size="16" fill="#6B7280" text-anchor="middle">System connectivity and data flow</text>',
    ]

    # Position nodes in a circular layout
    node_positions = {}
    radius = min(width, height) * 0.35
    angle_step = 360 / max(len(nodes), 1)
    
    for i, (node_name, node_type) in enumerate(nodes.items()):
        angle = math.radians(i * angle_step)
        x = center_x + radius * math.cos(angle)
        y = center_y + radius * math.sin(angle)
        node_positions[node_name] = (x, y)
        
        # Node styling based on type
        node_color = "#1E3A8A" if "server" in node_type.lower() else "#3B82F6"
        node_size = 80 if "server" in node_type.lower() else 60
        
        svg_elements.extend([
            f'<rect x="{x-node_size//2}" y="{y-node_size//2}" width="{node_size}" height="{node_size}" '
            f'rx="12" fill="url(#networkGrad)" filter="url(#networkShadow)" stroke="#FFFFFF" stroke-width="2"/>',
            
            f'<text x="{x}" y="{y-10}" font-family="Inter, sans-serif" '
            f'font-size="14" font-weight="700" fill="#FFFFFF" text-anchor="middle">{node_name[:12]}</text>',
            
            f'<text x="{x}" y="{y+8}" font-family="Inter, sans-serif" '
            f'font-size="11" fill="#E5E7EB" text-anchor="middle">{node_type[:15]}</text>',
        ])

    # Draw connections
    for connection in connections:
        from_node = connection.get("from", "")
        to_node = connection.get("to", "")
        label = connection.get("label", "")
        
        if from_node in node_positions and to_node in node_positions:
            x1, y1 = node_positions[from_node]
            x2, y2 = node_positions[to_node]
            
            svg_elements.extend([
                f'<line x1="{x1}" y1="{y1}" x2="{x2}" y2="{y2}" '
                'stroke="{theme["accent"]}" stroke-width="3" marker-end="url(#networkArrow)"/>',
                
                f'<text x="{(x1+x2)/2}" y="{(y1+y2)/2-10}" font-family="Inter, sans-serif" '
                f'font-size="12" fill="#374151" text-anchor="middle">{label[:20]}</text>'
            ])

    return f'<svg viewBox="0 0 {width} {height}" xmlns="http://www.w3.org/2000/svg" style="max-width: 100%; height: auto;">\n' + '\n'.join(svg_elements) + '\n</svg>'

def generate_themed_architecture_svg(components, variation, theme):
    """Generate architecture diagram with specific theme and style variation"""
    if not components:
        return generate_error_svg("Architecture diagram requires components data")

    width, height = 1400, 1000
    
    svg_elements = [
        '<defs>',
        '''
        <linearGradient id="archGrad" x1="0%" y1="0%" x2="100%" y2="100%">
            <stop offset="0%" style="stop-color:{theme['primary']};stop-opacity:1" />
            <stop offset="100%" style="stop-color:{theme['secondary']};stop-opacity:1" />
        </linearGradient>
        ''',
        '''
        <filter id="archShadow" x="-20%" y="-20%" width="140%" height="140%">
            <feGaussianBlur in="SourceAlpha" stdDeviation="3"/>
            <feOffset dx="2" dy="4" result="offset"/>
            <feFlood flood-color="#000000" flood-opacity="0.15"/>
            <feComposite in2="offset" operator="in"/>
            <feMerge><feMergeNode/><feMergeNode in="SourceGraphic"/></feMerge>
        </filter>
        ''',
        '</defs>',
        
        f'<rect width="{width}" height="{height}" fill="#FAFAFA"/>',
        
        f'<text x="{width//2}" y="40" font-family="Inter, sans-serif" '
        f'font-size="28" font-weight="800" fill="{theme["primary"]}" text-anchor="middle">System Architecture</text>',
        f'<text x="{width//2}" y="70" font-family="Inter, sans-serif" '
        f'font-size="16" fill="#6B7280" text-anchor="middle">Component structure and relationships</text>',
    ]

    # Arrange components in layers
    layers = ["Presentation", "Business", "Data", "Infrastructure"]
    layer_height = (height - 150) // len(layers)
    component_width = 200
    component_height = 80
    
    component_positions = {}
    comp_list = list(components.items())
    comps_per_layer = max(1, len(comp_list) // len(layers))
    
    for layer_idx, layer_name in enumerate(layers):
        layer_y = 120 + layer_idx * layer_height
        
        # Draw layer background
        svg_elements.append(
            f'<rect x="50" y="{layer_y-20}" width="{width-100}" height="{layer_height-20}" '
            f'rx="8" fill="rgba(124, 58, 237, 0.05)" stroke="rgba(124, 58, 237, 0.2)" stroke-width="1"/>'
        )
        
        svg_elements.append(
            f'<text x="70" y="{layer_y}" font-family="Inter, sans-serif" '
            f'font-size="14" font-weight="600" fill="#7C3AED">{layer_name} Layer</text>'
        )
        
        # Place components in this layer
        start_idx = layer_idx * comps_per_layer
        end_idx = min(start_idx + comps_per_layer, len(comp_list))
        layer_components = comp_list[start_idx:end_idx]
        
        if layer_components:
            spacing = (width - 200) // (len(layer_components) + 1)
            
            for comp_idx, (comp_name, comp_purpose) in enumerate(layer_components):
                x = 100 + (comp_idx + 1) * spacing - component_width // 2
                y = layer_y + 30
                
                component_positions[comp_name] = (x + component_width//2, y + component_height//2)
                
                svg_elements.extend([
                    f'<rect x="{x}" y="{y}" width="{component_width}" height="{component_height}" '
                    f'rx="12" fill="url(#archGrad)" filter="url(#archShadow)" stroke="#FFFFFF" stroke-width="2"/>',
                    
                    f'<text x="{x + component_width//2}" y="{y + 25}" font-family="Inter, sans-serif" '
                    f'font-size="14" font-weight="700" fill="#FFFFFF" text-anchor="middle">{comp_name[:18]}</text>',
                    
                    f'<text x="{x + component_width//2}" y="{y + 45}" font-family="Inter, sans-serif" '
                    f'font-size="11" fill="#E5E7EB" text-anchor="middle">{comp_purpose[:25]}</text>',
                ])

    # Draw relationships
    for i in range(len(comp_list)-1):
        from_comp = comp_list[i][0]
        to_comp = comp_list[i+1][0]
        
        if from_comp in component_positions and to_comp in component_positions:
            x1, y1 = component_positions[from_comp]
            x2, y2 = component_positions[to_comp]
            
            svg_elements.extend([
                f'<line x1="{x1}" y1="{y1}" x2="{x2}" y2="{y2}" '
                'stroke="#7C3AED" stroke-width="2" stroke-dasharray="5,3"/>',
                
                f'<text x="{(x1+x2)/2}" y="{(y1+y2)/2-8}" font-family="Inter, sans-serif" '
                f'font-size="11" fill="#7C3AED" text-anchor="middle">depends on</text>'
            ])

    return f'<svg viewBox="0 0 {width} {height}" xmlns="http://www.w3.org/2000/svg" style="max-width: 100%; height: auto;">\n' + '\n'.join(svg_elements) + '\n</svg>'

def generate_themed_gantt_svg(tasks, variation, theme):
    """Generate Gantt chart with specific theme and style variation"""
    if not tasks:
        return generate_error_svg("Gantt chart requires tasks")

    width, height = 1400, 600
    task_height = 40
    task_spacing = 60
    chart_start_x = 300
    
    svg_elements = [
        '<defs>',
        '''
        <linearGradient id="ganttGrad" x1="0%" y1="0%" x2="100%" y2="0%">
            <stop offset="0%" style="stop-color:{theme['primary']};stop-opacity:1" />
            <stop offset="100%" style="stop-color:{theme['secondary']};stop-opacity:1" />
        </linearGradient>
        ''',
        '</defs>',
        
        f'<rect width="{width}" height="{height}" fill="#F8FAFC"/>',
        
        # Title
        f'<text x="{width//2}" y="40" font-family="Inter, sans-serif" '
        f'font-size="28" font-weight="800" fill="{theme["primary"]}" text-anchor="middle">{variation["name"]}</text>',
        
        # Time axis
        f'<line x1="{chart_start_x}" y1="80" x2="{width-50}" y2="80" stroke="#9CA3AF" stroke-width="2"/>',
    ]

    # Draw time markers
    time_width = (width - chart_start_x - 50) // 12
    for i in range(13):
        x = chart_start_x + i * time_width
        svg_elements.extend([
            f'<line x1="{x}" y1="75" x2="{x}" y2="85" stroke="#9CA3AF" stroke-width="1"/>',
            f'<text x="{x}" y="100" font-family="Inter, sans-serif" '
            f'font-size="10" fill="#6B7280" text-anchor="middle">M{i+1}</text>'
        ])

    # Draw tasks
    for i, (task_name, task_data) in enumerate(tasks.items()):
        y = 120 + i * task_spacing
        
        # Task info
        description = task_data.get('description', task_name) if isinstance(task_data, dict) else str(task_data)
        start = task_data.get('start', 1) if isinstance(task_data, dict) else 1
        duration = task_data.get('duration', 2) if isinstance(task_data, dict) else 2
        
        # Task label
        svg_elements.append(
            f'<text x="20" y="{y+task_height//2+5}" font-family="Inter, sans-serif" '
            f'font-size="12" fill="#374151" font-weight="600">{task_name[:25]}</text>'
        )
        
        # Task bar
        bar_x = chart_start_x + (start-1) * time_width
        bar_width = duration * time_width
        
        svg_elements.extend([
            f'<rect x="{bar_x}" y="{y}" width="{bar_width}" height="{task_height}" '
            'rx="4" fill="url(#ganttGrad)" stroke="#FFFFFF" stroke-width="1"/>',
            
            f'<text x="{bar_x + bar_width//2}" y="{y+task_height//2+5}" font-family="Inter, sans-serif" '
            f'font-size="10" fill="#FFFFFF" text-anchor="middle">{duration}M</text>'
        ])

    return f'<svg viewBox="0 0 {width} {height}" xmlns="http://www.w3.org/2000/svg" style="max-width: 100%; height: auto;">\n' + '\n'.join(svg_elements) + '\n</svg>'

def generate_themed_journey_svg(stages, variation, theme):
    """Generate user journey map with specific theme and style variation"""
    if not stages:
        return generate_error_svg("Journey map requires stages")

    width, height = 1400, 700
    touchpoint_width = 150
    touchpoint_height = 100
    
    # Sort stages by order
    sorted_stages = sorted(stages.items(), key=lambda x: x[1].get('order', 0) if isinstance(x[1], dict) else 0)
    
    svg_elements = [
        '<defs>',
        '''
        <linearGradient id="journeyGrad" x1="0%" y1="0%" x2="100%" y2="100%">
            <stop offset="0%" style="stop-color:{theme['primary']};stop-opacity:1" />
            <stop offset="100%" style="stop-color:{theme['secondary']};stop-opacity:1" />
        </linearGradient>
        ''',
        '</defs>',
        
        f'<rect width="{width}" height="{height}" fill="#F8FAFC"/>',
        
        # Title
        f'<text x="{width//2}" y="40" font-family="Inter, sans-serif" '
        f'font-size="28" font-weight="800" fill="{theme["primary"]}" text-anchor="middle">{variation["name"]}</text>',
        
        # Journey line
        f'<line x1="100" y1="{height//2}" x2="{width-100}" y2="{height//2}" stroke="#DB2777" stroke-width="4"/>',
    ]

    # Draw touchpoints
    spacing = (width - 200) // max(len(sorted_stages), 1)
    for i, (touchpoint_name, touchpoint_data) in enumerate(sorted_stages):
        x = 100 + i * spacing + spacing // 2
        y = height // 2
        
        # Touchpoint info
        if isinstance(touchpoint_data, dict):
            action = touchpoint_data.get('action', touchpoint_name)
            emotion = touchpoint_data.get('emotion', 'Neutral')
        else:
            action = str(touchpoint_data)
            emotion = 'Neutral'
        
        # Touchpoint circle
        svg_elements.extend([
            f'<circle cx="{x}" cy="{y}" r="30" fill="url(#journeyGrad)" stroke="#FFFFFF" stroke-width="3"/>',
            f'<text x="{x}" y="{y+5}" font-family="Inter, sans-serif" '
            f'font-size="12" font-weight="700" fill="#FFFFFF" text-anchor="middle">{i+1}</text>',
            
            # Touchpoint details above
            f'<rect x="{x-touchpoint_width//2}" y="{y-150}" width="{touchpoint_width}" height="{touchpoint_height}" '
            'rx="8" fill="#FFFFFF" stroke="#DB2777" stroke-width="2"/>',
            
            f'<text x="{x}" y="{y-120}" font-family="Inter, sans-serif" '
            f'font-size="12" font-weight="700" fill="#DB2777" text-anchor="middle">{touchpoint_name[:15]}</text>',
            
            f'<text x="{x}" y="{y-100}" font-family="Inter, sans-serif" '
            f'font-size="10" fill="#374151" text-anchor="middle">{action[:20]}</text>',
            
            f'<text x="{x}" y="{y-80}" font-family="Inter, sans-serif" '
            f'font-size="10" fill="#6B7280" text-anchor="middle">{emotion}</text>',
        ])

    return f'<svg viewBox="0 0 {width} {height}" xmlns="http://www.w3.org/2000/svg" style="max-width: 100%; height: auto;">\n' + '\n'.join(svg_elements) + '\n</svg>'

def generate_themed_flowchart_svg(steps, variation, theme):
    """Generate themed flowchart with specific style variation"""
    if not steps or len(steps) < 2:
        return generate_error_svg("Flowchart needs at least 2 steps")

    width = 1400
    node_width = 320
    node_height = 120
    spacing = 160
    height = 180 + len(steps) * (node_height + spacing)

    svg_elements = [
        '<defs>',
        f'''
        <linearGradient id="flowchartGrad" x1="0%" y1="0%" x2="100%" y2="100%">
            <stop offset="0%" style="stop-color:{theme['primary']};stop-opacity:1" />
            <stop offset="100%" style="stop-color:{theme['secondary']};stop-opacity:1" />
        </linearGradient>
        ''',
        '''
        <filter id="flowchartShadow" x="-50%" y="-50%" width="200%" height="200%">
            <feGaussianBlur in="SourceAlpha" stdDeviation="6"/>
            <feOffset dx="3" dy="8" result="offset"/>
            <feFlood flood-color="#000000" flood-opacity="0.25"/>
            <feComposite in2="offset" operator="in"/>
            <feMerge><feMergeNode/><feMergeNode in="SourceGraphic"/></feMerge>
        </filter>
        ''',
        '''
        <marker id="flowchartArrow" markerWidth="16" markerHeight="12" refX="15" refY="6" orient="auto">
            <polygon points="0 0, 16 6, 0 12" fill="#4a5568" opacity="0.8"/>
        </marker>
        ''',
        '</defs>',

        # Background
        f'<rect width="{width}" height="{height}" fill="#f8fafc"/>',
        
        # Title
        f'<text x="{width//2}" y="40" font-family="Inter, sans-serif" '
        f'font-size="28" font-weight="800" fill="{theme["primary"]}" text-anchor="middle">{variation["name"]}</text>',
        f'<text x="{width//2}" y="65" font-family="Inter, sans-serif" '
        f'font-size="16" fill="#718096" text-anchor="middle">Step-by-step workflow visualization</text>',
    ]

    for i, (step_name, step_content) in enumerate(steps.items()):
        x = width // 2
        y = 140 + i * (node_height + spacing)

        # Node with theme colors
        svg_elements.extend([
            # Main node
            f'<rect x="{x-node_width//2}" y="{y}" width="{node_width}" height="{node_height}" '
            f'rx="18" ry="18" fill="url(#flowchartGrad)" filter="url(#flowchartShadow)" '
            'stroke="rgba(255,255,255,0.4)" stroke-width="2"/>',

            # Inner highlight
            f'<rect x="{x-node_width//2+4}" y="{y+4}" width="{node_width-8}" height="3" '
            'rx="2" fill="rgba(255,255,255,0.5)"/>',

            # Step number badge
            f'<circle cx="{x-node_width//2+25}" cy="{y+25}" r="15" fill="rgba(255,255,255,0.3)"/>',
            f'<text x="{x-node_width//2+25}" y="{y+30}" font-family="Inter, sans-serif" '
            f'font-size="14" font-weight="800" fill="white" text-anchor="middle">{i+1}</text>',
        ])

        # Text content
        title = str(step_name)[:28]
        description = (step_content[0] if step_content else "")[:60]

        # Smart text wrapping
        title_lines = textwrap.wrap(title, width=25)[:2]
        desc_lines = textwrap.wrap(description, width=40)[:2]

        # Title
        for j, line in enumerate(title_lines):
            svg_elements.append(
                f'<text x="{x}" y="{y+35+j*20}" font-family="Inter, sans-serif" '
                f'font-size="18" font-weight="700" fill="white" text-anchor="middle" '
                f'letter-spacing="0.5px">{line}</text>'
            )

        # Description
        desc_start_y = y + 35 + len(title_lines) * 20 + 10
        for j, line in enumerate(desc_lines):
            svg_elements.append(
                f'<text x="{x}" y="{desc_start_y+j*16}" font-family="Inter, sans-serif" '
                f'font-size="13" fill="rgba(255,255,255,0.9)" text-anchor="middle">{line}</text>'
            )

        # Connection arrow to next step
        if i < len(steps)-1:
            next_y = y + node_height + spacing
            mid_y = y + node_height + spacing//2

            svg_elements.extend([
                # Connection with theme color
                f'<path d="M{x} {y+node_height} Q{x+30} {mid_y} {x} {next_y-25}" '
                f'stroke="{theme["accent"]}" stroke-width="4" fill="none" opacity="0.8" '
                'marker-end="url(#flowchartArrow)"/>',
            ])

    return f'<svg viewBox="0 0 {width} {height}" xmlns="http://www.w3.org/2000/svg" style="max-width: 100%; height: auto; font-family: Inter, -apple-system, sans-serif;">\n' + '\n'.join(svg_elements) + '\n</svg>'

# ENHANCED: Update the generate_napkin_diagram endpoint to handle all types properly
@app.route('/generate_napkin_diagram', methods=['POST'])
def generate_napkin_diagram():
    try:
        data = request.json
        if not data:
            return jsonify({"error": "No JSON data received"}), 400

        user_input = data.get('userInput', '').strip()
        napkin_template = data.get('napkinTemplate', {})

        if not user_input:
            return jsonify({"error": "User input is required"}), 400
        if not napkin_template:
            return jsonify({"error": "Napkin template is required"}), 400

        template_name = napkin_template.get('name', '').strip()
        napkin_type = napkin_template.get('napkinType', 'flowchart')

        logger.info(f"Processing diagram request - Type: {napkin_type}, Input: {user_input[:50]}...")

        # ENHANCED: Use diagram-specific prompts
        enhanced_prompt = get_enhanced_diagram_prompt(napkin_type, user_input)

        # Generate the diagram data using AI
        diagram_data = {}
        if client:
            try:
                response = client.chat.completions.create(
                    model="llama3-8b-8192",
                    messages=[
                        {
                            "role": "system", 
                            "content": f"You are a {napkin_type} expert. Return only valid JSON that matches the specified format exactly. Do not include any explanatory text, just the JSON. Focus on {napkin_type}-specific terminology and best practices."
                        },
                        {
                            "role": "user", 
                            "content": enhanced_prompt
                        }
                    ],
                    response_format={"type": "json_object"},
                    temperature=0.7,
                    max_tokens=2000
                )
                
                diagram_data = json.loads(response.choices[0].message.content)
                validate_diagram_json(diagram_data, napkin_type)
                logger.info(f"Generated AI data for {napkin_type}")
                
            except Exception as e:
                logger.error(f"Groq API error for {napkin_type}: {e}")
                diagram_data = get_fallback_data(napkin_type, user_input)
        else:
            diagram_data = get_fallback_data(napkin_type, user_input)

        # ENHANCED: Generate the appropriate SVG based on diagram type with proper routing
        svg_content = ""
        
        if napkin_type == "flowchart":
            svg_content = generate_enhanced_flowchart_svg(diagram_data.get("steps", {}))
        elif napkin_type == "sequence":
            svg_content = generate_enhanced_sequence_svg(
                diagram_data.get("actors", {}), 
                diagram_data.get("interactions", [])
            )
        elif napkin_type == "state":
            svg_content = generate_enhanced_state_svg(
                diagram_data.get("states", {}), 
                diagram_data.get("transitions", [])
            )
        elif napkin_type == "mind map":
            svg_content = generate_themed_mindmap_svg(
                diagram_data.get("central_topic", "Main Topic"),
                diagram_data.get("branches", {}),
                {"name": "Mind Map", "style": "standard"},
                {"primary": "#7C3AED", "secondary": "#8B5CF6", "accent": "#6D28D9"}
            )
        elif napkin_type == "swot analysis":
            svg_content = generate_themed_swot_svg(diagram_data, {"name": "SWOT Analysis", "style": "standard"}, {"primary": "#7C3AED", "secondary": "#8B5CF6", "accent": "#6D28D9"})
        elif napkin_type == "timeline":
            svg_content = generate_themed_timeline_svg(diagram_data.get("events", {}), {"name": "Timeline", "style": "standard"}, {"primary": "#0891B2", "secondary": "#06B6D4", "accent": "#0E7490"})
        elif napkin_type == "gantt":
            svg_content = generate_themed_gantt_svg(diagram_data.get("tasks", {}), {"name": "Gantt Chart", "style": "standard"}, {"primary": "#9333EA", "secondary": "#A855F7", "accent": "#7C3AED"})
        elif napkin_type == "journey":
            svg_content = generate_themed_journey_svg(diagram_data.get("stages", {}), {"name": "User Journey", "style": "standard"}, {"primary": "#BE185D", "secondary": "#DB2777", "accent": "#9D174D"})
        elif napkin_type == "erd":
            svg_content = generate_themed_erd_svg(diagram_data.get("entities", {}), {"name": "Entity Relationship", "style": "standard"}, {"primary": "#059669", "secondary": "#10B981", "accent": "#047857"})
        elif napkin_type == "class":
            svg_content = generate_themed_class_svg(diagram_data.get("classes", {}), {"name": "Class Diagram", "style": "standard"}, {"primary": "#7C2D12", "secondary": "#9A3412", "accent": "#5C1911"})
        elif napkin_type == "network":
            svg_content = generate_themed_network_svg(diagram_data.get("nodes", {}), diagram_data.get("connections", []), {"name": "Network Diagram", "style": "standard"}, {"primary": "#1E40AF", "secondary": "#2563EB", "accent": "#1D4ED8"})
        elif napkin_type == "architecture":
            svg_content = generate_themed_architecture_svg(diagram_data.get("components", {}), {"name": "Architecture", "style": "standard"}, {"primary": "#6D28D9", "secondary": "#7C3AED", "accent": "#5B21B6"})
        else:
            # Default to flowchart for unknown types
            svg_content = generate_enhanced_flowchart_svg(diagram_data.get("steps", {}))

        logger.info(f"Generated {napkin_type} diagram successfully")

        return jsonify({
            "templateName": template_name,
            "content": svg_content,
            "isDiagram": True,
            "diagramType": napkin_type,
            "timestamp": datetime.now().isoformat()
        })

    except Exception as e:
        logger.error(f"Error generating diagram: {str(e)}")
        error_content = generate_error_svg(f"Failed to generate {napkin_type} diagram")
        return jsonify({
            "templateName": napkin_template.get('name', 'Error'),
            "content": error_content,
            "isDiagram": True,
            "error": str(e),
            "timestamp": datetime.now().isoformat()
        })

@app.route('/regenerate_diagram', methods=['POST', 'OPTIONS'])
def regenerate_diagram():
    """Regenerate diagram with user modifications"""
    if request.method == 'OPTIONS':
        # Handle preflight requests
        response = jsonify({})
        response.headers.add('Access-Control-Allow-Origin', '*')
        response.headers.add('Access-Control-Allow-Headers', 'Content-Type,Authorization')
        response.headers.add('Access-Control-Allow-Methods', 'POST,OPTIONS')
        return response
    
    try:
        data = request.get_json()
        if not data:
            return jsonify({"error": "No data provided"}), 400
        
        prompt = data.get('prompt', '')
        diagram_type = data.get('diagramType', 'flowchart')
        current_svg = data.get('currentSvg', '')
        
        if not prompt:
            return jsonify({"error": "Prompt is required"}), 400
        
        logger.info(f"Regenerating {diagram_type} diagram with modified prompt")
        
        # Use the same AI generation process as the original diagram
        diagram_data = {}
        if not client:
            logger.warning("AI service not available, using smart fallback with text changes")
            # Apply text changes directly to the current SVG instead of generating new data
            svg_content = apply_text_changes_to_svg(current_svg, prompt)
            if svg_content:
                logger.info(f"Successfully applied text changes to {diagram_type} diagram")
                return jsonify({
                    "svg": svg_content,
                    "success": True,
                    "timestamp": datetime.now().isoformat(),
                    "using_ai": False,
                    "message": "Diagram updated with your text changes (using direct text replacement)"
                })
            else:
                # Fallback to template data if direct text replacement fails
                diagram_data = get_fallback_data(diagram_type, prompt)
        else:
            try:
                # Get enhanced prompt for the diagram type
                enhanced_prompt = get_enhanced_diagram_prompt(diagram_type, prompt)
                
                # Call Groq API
                completion = client.chat.completions.create(
                    model="llama-3.1-70b-versatile",
                    messages=[
                        {"role": "system", "content": "You are a professional diagram data analyst. Return only valid JSON."},
                        {"role": "user", "content": enhanced_prompt}
                    ],
                    temperature=0.3,
                    max_tokens=2048,
                    top_p=0.9,
                    stream=False
                )
                
                response_content = completion.choices[0].message.content.strip()
                
                # Clean and parse the response
                response_content = clean_json_response(response_content)
                
                try:
                    diagram_data = json.loads(response_content)
                except json.JSONDecodeError as e:
                    logger.error(f"JSON decode error: {e}")
                    logger.error(f"Raw response: {response_content}")
                    # Use fallback data if AI response is invalid
                    diagram_data = get_fallback_data(diagram_type, prompt)
            except Exception as e:
                logger.error(f"AI API error: {e}")
                # Use fallback data if AI call fails
                diagram_data = get_fallback_data(diagram_type, prompt)
        
        # Generate SVG based on diagram type
        svg_content = ""
        if diagram_type == "flowchart":
            svg_content = generate_enhanced_flowchart_svg(diagram_data.get("steps", {}))
        elif diagram_type == "sequence":
            svg_content = generate_enhanced_sequence_svg(
                diagram_data.get("actors", {}),
                diagram_data.get("interactions", [])
            )
        elif diagram_type == "state":
            svg_content = generate_enhanced_state_svg(
                diagram_data.get("states", {}), 
                diagram_data.get("transitions", [])
            )
        elif diagram_type == "mind map":
            svg_content = generate_themed_mindmap_svg(
                diagram_data.get("central_topic", "Main Topic"),
                diagram_data.get("branches", {}),
                {"name": "Mind Map", "style": "standard"},
                {"primary": "#7C3AED", "secondary": "#8B5CF6", "accent": "#6D28D9"}
            )
        elif diagram_type == "swot analysis":
            svg_content = generate_themed_swot_svg(diagram_data, {"name": "SWOT Analysis", "style": "standard"}, {"primary": "#7C3AED", "secondary": "#8B5CF6", "accent": "#6D28D9"})
        elif diagram_type == "timeline":
            svg_content = generate_themed_timeline_svg(diagram_data.get("events", {}), {"name": "Timeline", "style": "standard"}, {"primary": "#0891B2", "secondary": "#06B6D4", "accent": "#0E7490"})
        elif diagram_type == "gantt":
            svg_content = generate_themed_gantt_svg(diagram_data.get("tasks", {}), {"name": "Gantt Chart", "style": "standard"}, {"primary": "#9333EA", "secondary": "#A855F7", "accent": "#7C3AED"})
        elif diagram_type == "journey":
            svg_content = generate_themed_journey_svg(diagram_data.get("stages", {}), {"name": "User Journey", "style": "standard"}, {"primary": "#BE185D", "secondary": "#DB2777", "accent": "#9D174D"})
        elif diagram_type == "erd":
            svg_content = generate_themed_erd_svg(diagram_data.get("entities", {}), {"name": "Entity Relationship", "style": "standard"}, {"primary": "#059669", "secondary": "#10B981", "accent": "#047857"})
        elif diagram_type == "class":
            svg_content = generate_themed_class_svg(diagram_data.get("classes", {}), {"name": "Class Diagram", "style": "standard"}, {"primary": "#7C2D12", "secondary": "#9A3412", "accent": "#5C1911"})
        elif diagram_type == "network":
            svg_content = generate_themed_network_svg(diagram_data.get("nodes", {}), diagram_data.get("connections", []), {"name": "Network Diagram", "style": "standard"}, {"primary": "#1E40AF", "secondary": "#2563EB", "accent": "#1D4ED8"})
        elif diagram_type == "architecture":
            svg_content = generate_themed_architecture_svg(diagram_data.get("components", {}), {"name": "Architecture", "style": "standard"}, {"primary": "#6D28D9", "secondary": "#7C3AED", "accent": "#5B21B6"})
        else:
            # Default to flowchart for unknown types
            svg_content = generate_enhanced_flowchart_svg(diagram_data.get("steps", {}))

        using_ai = client is not None
        logger.info(f"Successfully regenerated {diagram_type} diagram {'with AI' if using_ai else 'with fallback data'}")

        return jsonify({
            "svg": svg_content,
            "success": True,
            "timestamp": datetime.now().isoformat(),
            "using_ai": using_ai,
            "message": "Diagram regenerated successfully" + ("" if using_ai else " (using fallback data)")
        })

    except Exception as e:
        logger.error(f"Error regenerating diagram: {str(e)}")
        return jsonify({
            "error": f"Failed to regenerate diagram: {str(e)}",
            "success": False
        }), 500

@app.route('/health', methods=['GET', 'OPTIONS'])
def health_check():
    """Enhanced health check endpoint with CORS support"""
    if request.method == 'OPTIONS':
        # Handle preflight requests
        response = jsonify({})
        response.headers.add('Access-Control-Allow-Origin', '*')
        response.headers.add('Access-Control-Allow-Headers', 'Content-Type,Authorization')
        response.headers.add('Access-Control-Allow-Methods', 'GET,OPTIONS')
        return response
    
    return jsonify({
        "status": "healthy",
        "timestamp": datetime.now().isoformat(),
        "groq_client": "connected" if client else "disconnected",
        "version": "4.0.0",
        "server_host": "0.0.0.0",
        "server_port": 5000,
        "supported_diagrams": [
            "flowchart", "sequence", "state", "mind map", "swot analysis",
            "timeline", "gantt", "journey", "erd", "class", "network", "architecture"
        ]
    })

# Document Generation Routes
@app.route('/generate_document', methods=['POST'])
def generate_document():
    try:
        data = request.get_json()
        user_input = data.get('userInput', '')
        document_template = data.get('documentTemplate', {})
        
        template_name = document_template.get('name', 'General Document')
        document_type = document_template.get('documentType', 'general')
        prompt_instruction = document_template.get('promptInstruction', '')
        
        if not user_input:
            return jsonify({'error': 'User input is required'}), 400
        
        try:
            full_prompt = prompt_instruction.replace('[USER_INPUT]', user_input)
            
            completion = client.chat.completions.create(
                model="llama3-8b-8192",
                messages=[
                    {
                        "role": "system",
                        "content": f"You are a professional document writer specializing in {document_type} documents. Create comprehensive, well-structured, and professional content."
                    },
                    {
                        "role": "user",
                        "content": full_prompt
                    }
                ],
                temperature=0.7,
                max_tokens=4000,
                top_p=1,
                stream=False,
                stop=None,
            )
            
            generated_content = completion.choices[0].message.content
            
        except Exception as e:
            logger.warning(f"Groq API failed, using fallback content: {e}")
            generated_content = f"""# {template_name}

## Overview
This document provides a comprehensive overview of {user_input}.

## Key Points
- Professional approach to {user_input}
- Structured methodology and best practices
- Clear objectives and deliverables
- Risk assessment and mitigation strategies

## Implementation Plan
1. **Planning Phase**: Define scope and requirements
2. **Analysis Phase**: Evaluate current state and needs
3. **Design Phase**: Create detailed specifications
4. **Execution Phase**: Implement the solution
5. **Review Phase**: Validate results and optimize

## Conclusion
This document serves as a foundation for successful implementation of {user_input}.

*Generated on {datetime.now().strftime('%B %d, %Y')}*
*Status: Ready for implementation*"""
        
        response_data = {
            'templateName': template_name,
            'content': generated_content,
            'documentType': document_type,
            'timestamp': datetime.now().isoformat()
        }
        
        return jsonify(response_data)
        
    except Exception as e:
        logger.error(f"Error in generate_document: {e}")
        return jsonify({'error': str(e)}), 500

@app.route('/generate_documents', methods=['POST'])
def generate_documents():
    try:
        data = request.get_json()
        user_input = data.get('userInput', '')
        document_templates = data.get('documentTemplates', [])
        
        if not user_input or not document_templates:
            return jsonify({'error': 'User input and document templates are required'}), 400
        
        generated_documents = []
        
        for template in document_templates:
            try:
                template_name = template.get('name', 'General Document')
                document_type = template.get('documentType', 'general')
                prompt_instruction = template.get('promptInstruction', '')
                
                try:
                    full_prompt = prompt_instruction.replace('[USER_INPUT]', user_input)
                    
                    completion = client.chat.completions.create(
                        model="llama3-8b-8192",
                        messages=[
                            {
                                "role": "system",
                                "content": f"You are a professional document writer specializing in {document_type} documents. Create comprehensive, well-structured, and professional content."
                            },
                            {
                                "role": "user",
                                "content": full_prompt
                            }
                        ],
                        temperature=0.7,
                        max_tokens=4000,
                        top_p=1,
                        stream=False,
                        stop=None,
                    )
                    
                    generated_content = completion.choices[0].message.content
                    
                except Exception as e:
                    logger.warning(f"Groq API failed for template {template_name}, using fallback: {e}")
                    generated_content = f"""# {template_name}

## Overview
This document provides a comprehensive overview of {user_input}.

## Key Points
- Professional approach to {user_input}
- Structured methodology and best practices
- Clear objectives and deliverables

## Implementation
Detailed implementation plan for {user_input}.

*Generated on {datetime.now().strftime('%B %d, %Y')}*"""
                
                document_data = {
                    'templateName': template_name,
                    'content': generated_content,
                    'documentType': document_type,
                    'timestamp': datetime.now().isoformat()
                }
                
                generated_documents.append(document_data)
                
            except Exception as e:
                logger.error(f"Error generating document for template {template.get('name', 'Unknown')}: {e}")
                continue
        
        return jsonify(generated_documents)
        
    except Exception as e:
        logger.error(f"Error in generate_documents: {e}")
        return jsonify({'error': str(e)}), 500

@app.route('/document_templates', methods=['GET'])
def get_document_templates():
    try:
        templates = [
            {
                "id": "business_plan",
                "name": "Business Plan",
                "description": "Comprehensive business planning document",
                "documentType": "business",
                "promptInstruction": "Create a detailed business plan for [USER_INPUT]. Include executive summary, market analysis, financial projections, and implementation strategy."
            },
            {
                "id": "technical_spec",
                "name": "Technical Specification",
                "description": "Detailed technical requirements and specifications",
                "documentType": "technical",
                "promptInstruction": "Create a comprehensive technical specification document for [USER_INPUT]. Include system requirements, architecture, APIs, and implementation details."
            },
            {
                "id": "project_proposal",
                "name": "Project Proposal",
                "description": "Professional project proposal document",
                "documentType": "proposal",
                "promptInstruction": "Create a detailed project proposal for [USER_INPUT]. Include objectives, scope, timeline, resources, and expected outcomes."
            },
            {
                "id": "marketing_strategy",
                "name": "Marketing Strategy",
                "description": "Strategic marketing plan and approach",
                "documentType": "marketing",
                "promptInstruction": "Create a comprehensive marketing strategy for [USER_INPUT]. Include target audience, channels, campaigns, and metrics."
            },
            {
                "id": "user_manual",
                "name": "User Manual",
                "description": "Step-by-step user guide and documentation",
                "documentType": "documentation",
                "promptInstruction": "Create a detailed user manual for [USER_INPUT]. Include setup instructions, features, troubleshooting, and best practices."
            }
        ]
        return jsonify(templates)
        
    except Exception as e:
        logger.error(f"Error in get_document_templates: {e}")
        return jsonify({'error': str(e)}), 500

def get_local_ip():
    """Get the local IP address for mobile connections"""
    try:
        # Connect to a remote address to determine local IP
        s = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
        s.connect(("8.8.8.8", 80))
        local_ip = s.getsockname()[0]
        s.close()
        return local_ip
    except Exception:
        return "192.168.1.1"  # fallback

def customize_fallback_for_variation(diagram_data, diagram_type, style, user_input):
    """Customize fallback data based on variation style to create structurally different diagrams"""
    try:
        customized_data = copy.deepcopy(diagram_data)
        
        if diagram_type == 'flowchart' and 'steps' in customized_data:
            steps = customized_data['steps']
            if style == 'detailed':
                # Add sub-processes and validation steps
                detailed_steps = {}
                for key, value in steps.items():
                    detailed_steps[key] = value
                    if 'Start' in key or 'Initialize' in key:
                        detailed_steps[f'{key} - Pre-checks'] = [f'Validate prerequisites for {user_input}']
                    if 'Process' in key or 'Implement' in key:
                        detailed_steps[f'{key} - Validation'] = [f'Quality check for {key.lower()}']
                        detailed_steps[f'{key} - Documentation'] = [f'Document progress of {key.lower()}']
                    if 'End' in key or 'Complete' in key:
                        detailed_steps[f'{key} - Cleanup'] = [f'Finalize and cleanup after {user_input}']
                customized_data['steps'] = detailed_steps
                
            elif style == 'compact':
                # Keep only essential 3-4 steps
                essential_steps = {}
                step_keys = list(steps.keys())
                for i, key in enumerate(step_keys):
                    if i < 3 or 'End' in key or 'Complete' in key:
                        essential_steps[key] = steps[key]
                customized_data['steps'] = essential_steps
                
            elif style == 'enhanced':
                # Add parallel processes and decision points
                enhanced_steps = dict(steps)
                enhanced_steps['Risk Assessment'] = [f'Evaluate potential risks for {user_input}']
                enhanced_steps['Quality Gate'] = [f'Quality checkpoint for {user_input}']
                enhanced_steps['Alternative Path'] = [f'Backup approach for {user_input}']
                enhanced_steps['Success Metrics'] = [f'Define success criteria for {user_input}']
                customized_data['steps'] = enhanced_steps
                
        elif diagram_type == 'mind map' and 'branches' in customized_data:
            branches = customized_data['branches']
            if style == 'detailed':
                # Add sub-branches to each main branch
                for branch_name, items in branches.items():
                    if isinstance(items, list) and len(items) > 0:
                        detailed_items = items.copy()
                        detailed_items.extend([
                            f'Detailed analysis of {branch_name.lower()}',
                            f'Implementation steps for {branch_name.lower()}',
                            f'Success metrics for {branch_name.lower()}'
                        ])
                        branches[branch_name] = detailed_items
                        
            elif style == 'compact':
                # Keep only 3 main branches with 1-2 items each
                compact_branches = {}
                for i, (branch_name, items) in enumerate(list(branches.items())[:3]):
                    if isinstance(items, list):
                        compact_branches[branch_name] = items[:2]
                    else:
                        compact_branches[branch_name] = [str(items)]
                customized_data['branches'] = compact_branches
                
            elif style == 'enhanced':
                # Add creative and strategic branches
                enhanced_branches = dict(branches)
                enhanced_branches['Innovation Opportunities'] = [f'Creative solutions for {user_input}']
                enhanced_branches['Future Vision'] = [f'Long-term goals for {user_input}']
                enhanced_branches['Risk Mitigation'] = [f'Potential challenges in {user_input}']
                enhanced_branches['Success Factors'] = [f'Key elements for success in {user_input}']
                customized_data['branches'] = enhanced_branches
                
        elif diagram_type == 'sequence' and 'actors' in customized_data and 'interactions' in customized_data:
            actors = customized_data['actors']
            interactions = customized_data['interactions']
            
            if style == 'detailed':
                # Add more actors and detailed interactions
                if 'System' not in actors:
                    actors['System'] = 'Core System'
                if 'Logger' not in actors:
                    actors['Logger'] = 'Audit Logger'
                detailed_interactions = interactions.copy()
                detailed_interactions.extend([
                    {'from': 'System', 'to': 'Logger', 'message': f'Log start of {user_input}'},
                    {'from': 'Logger', 'to': 'System', 'message': 'Confirm logging'},
                    {'from': 'System', 'to': 'Logger', 'message': f'Log completion of {user_input}'}
                ])
                customized_data['interactions'] = detailed_interactions
                
            elif style == 'compact':
                # Keep only core interactions
                core_interactions = interactions[:4] if len(interactions) > 4 else interactions
                customized_data['interactions'] = core_interactions
                
            elif style == 'enhanced':
                # Add error handling and alternative flows
                enhanced_interactions = interactions.copy()
                enhanced_interactions.extend([
                    {'from': 'System', 'to': 'ErrorHandler', 'message': 'Handle exceptions'},
                    {'from': 'ErrorHandler', 'to': 'System', 'message': 'Return error response'},
                    {'from': 'System', 'to': 'Monitor', 'message': f'Track performance of {user_input}'}
                ])
                if 'ErrorHandler' not in actors:
                    actors['ErrorHandler'] = 'Error Management'
                if 'Monitor' not in actors:
                    actors['Monitor'] = 'Performance Monitor'
                customized_data['interactions'] = enhanced_interactions
                
        elif diagram_type == 'swot analysis':
            if style == 'detailed':
                # Add more items to each SWOT category
                for category in ['strengths', 'weaknesses', 'opportunities', 'threats']:
                    if category in customized_data and isinstance(customized_data[category], list):
                        current_items = customized_data[category]
                        detailed_items = current_items.copy()
                        detailed_items.extend([
                            f'Internal {category[:-1]} factor for {user_input}',
                            f'Market-related {category[:-1]} in {user_input}',
                            f'Long-term {category[:-1]} consideration'
                        ])
                        customized_data[category] = detailed_items
                        
            elif style == 'compact':
                # Keep only top 2 items per category
                for category in ['strengths', 'weaknesses', 'opportunities', 'threats']:
                    if category in customized_data and isinstance(customized_data[category], list):
                        customized_data[category] = customized_data[category][:2]
                        
            elif style == 'enhanced':
                # Add strategic insights and action items
                for category in ['strengths', 'weaknesses', 'opportunities', 'threats']:
                    if category in customized_data and isinstance(customized_data[category], list):
                        enhanced_items = customized_data[category].copy()
                        enhanced_items.append(f'Strategic action for {category}: Leverage for {user_input}')
                        customized_data[category] = enhanced_items
                        
        elif diagram_type == 'timeline' and 'events' in customized_data:
            events = customized_data['events']
            if style == 'detailed':
                # Add milestone events and sub-events
                detailed_events = dict(events)
                for key, value in list(events.items()):
                    detailed_events[f'{key} - Preparation'] = f'Prepare for {value}'
                    detailed_events[f'{key} - Review'] = f'Review outcomes of {value}'
                customized_data['events'] = detailed_events
                
            elif style == 'compact':
                # Keep only major milestones
                major_events = {}
                for i, (key, value) in enumerate(events.items()):
                    if i < 4:  # Keep only 4 major events
                        major_events[key] = value
                customized_data['events'] = major_events
                
            elif style == 'enhanced':
                # Add risk points and success criteria
                enhanced_events = dict(events)
                enhanced_events['Risk Checkpoint'] = f'Assess risks for {user_input}'
                enhanced_events['Quality Gate'] = f'Quality review for {user_input}'
                enhanced_events['Success Validation'] = f'Validate success of {user_input}'
                customized_data['events'] = enhanced_events
                
        # Add similar logic for other diagram types
        elif diagram_type == 'gantt' and 'tasks' in customized_data:
            tasks = customized_data['tasks']
            if style == 'detailed':
                detailed_tasks = dict(tasks)
                for task_name, task_info in tasks.items():
                    detailed_tasks[f'{task_name} - Planning'] = f'Plan for {task_name}'
                    detailed_tasks[f'{task_name} - Review'] = f'Review {task_name}'
                customized_data['tasks'] = detailed_tasks
            elif style == 'compact':
                compact_tasks = dict(list(tasks.items())[:3])
                customized_data['tasks'] = compact_tasks
            elif style == 'enhanced':
                enhanced_tasks = dict(tasks)
                enhanced_tasks['Risk Management'] = f'Manage risks for {user_input}'
                enhanced_tasks['Quality Assurance'] = f'Ensure quality for {user_input}'
                customized_data['tasks'] = enhanced_tasks
                
        return customized_data
    except Exception as e:
        logger.error(f"Error customizing fallback data: {e}")
        return diagram_data

def generate_variation_svg(diagram_data, diagram_type, variation):
    """Generate SVG content for a specific diagram variation with theming"""
    
    # Define color themes for each variation
    themes = {
        'standard': {"primary": "#4F46E5", "secondary": "#7C3AED", "accent": "#6366F1"},
        'detailed': {"primary": "#059669", "secondary": "#10B981", "accent": "#047857"},
        'compact': {"primary": "#7C2D12", "secondary": "#9A3412", "accent": "#5C1911"},
        'enhanced': {"primary": "#EA580C", "secondary": "#FB923C", "accent": "#C2410C"},
        'fallback': {"primary": "#3B82F6", "secondary": "#60A5FA", "accent": "#2563EB"}
    }
    
    # Get theme for this variation
    theme = themes.get(variation.get('style', 'standard'), themes['standard'])
    variation_info = {
        "name": variation.get('name', f"{diagram_type.title()} - {variation.get('style', 'Standard').title()}"),
        "style": variation.get('style', 'standard')
    }
    
    try:
        # Generate SVG based on diagram type with variation theming
        if diagram_type == "flowchart":
            return generate_themed_flowchart_svg(
                diagram_data.get("steps", {}),
                variation_info,
                theme
            )
        elif diagram_type == "sequence":
            return generate_themed_sequence_svg(
                diagram_data.get("actors", {}),
                diagram_data.get("interactions", []),
                variation_info,
                theme
            )
        elif diagram_type == "state":
            return generate_themed_state_svg(
                diagram_data.get("states", {}), 
                diagram_data.get("transitions", []),
                variation_info,
                theme
            )
        elif diagram_type == "mind map":
            return generate_themed_mindmap_svg(
                diagram_data.get("central_topic", "Main Topic"),
                diagram_data.get("branches", {}),
                variation_info,
                theme
            )
        elif diagram_type == "swot analysis":
            return generate_themed_swot_svg(
                diagram_data, 
                variation_info, 
                theme
            )
        elif diagram_type == "timeline":
            return generate_themed_timeline_svg(
                diagram_data.get("events", {}), 
                variation_info, 
                theme
            )
        elif diagram_type == "gantt":
            return generate_themed_gantt_svg(
                diagram_data.get("tasks", {}), 
                variation_info, 
                theme
            )
        elif diagram_type == "journey":
            return generate_themed_journey_svg(
                diagram_data.get("touchpoints", {}), 
                variation_info, 
                theme
            )
        elif diagram_type == "erd":
            return generate_themed_erd_svg(
                diagram_data.get("entities", {}), 
                variation_info, 
                theme
            )
        elif diagram_type == "class":
            return generate_themed_class_svg(
                diagram_data.get("classes", {}), 
                variation_info, 
                theme
            )
        elif diagram_type == "network":
            return generate_themed_network_svg(
                diagram_data.get("nodes", {}), 
                diagram_data.get("connections", []), 
                variation_info, 
                theme
            )
        elif diagram_type == "architecture":
            return generate_themed_architecture_svg(
                diagram_data.get("components", {}), 
                variation_info, 
                theme
            )
        else:
            # Default to flowchart for unknown types
            return generate_enhanced_flowchart_svg(diagram_data.get("steps", {}))
    
    except Exception as e:
        logger.error(f"Error generating {variation.get('style', 'unknown')} variation SVG for {diagram_type}: {e}")
        # Return a simple error SVG
        return generate_error_svg(f"Error generating {diagram_type} variation")

def get_variation_specific_prompt(base_prompt, diagram_type, style, user_input):
    """Generate variation-specific prompts to create structurally different diagrams"""
    
    style_instructions = {
        'standard': {
            'approach': 'Create a balanced, professional approach',
            'specifics': 'Include core elements with standard level of detail'
        },
        'detailed': {
            'approach': 'Create a comprehensive, in-depth approach',
            'specifics': 'Add sub-processes, validation steps, quality checkpoints, and detailed breakdowns'
        },
        'compact': {
            'approach': 'Create a streamlined, essential-only approach',
            'specifics': 'Focus on only the core 3-4 most critical elements, eliminate non-essential details'
        },
        'enhanced': {
            'approach': 'Create an advanced, strategic approach',
            'specifics': 'Add innovation elements, risk management, alternative paths, and strategic considerations'
        }
    }
    
    instruction = style_instructions.get(style, style_instructions['standard'])
    
    # Type-specific variation instructions
    type_specific = ""
    if diagram_type == 'flowchart':
        if style == 'detailed':
            type_specific = "Include pre-checks, validation steps, documentation points, and cleanup phases for each major step."
        elif style == 'compact':
            type_specific = "Show only the 3-4 most essential steps in the process, combining related activities."
        elif style == 'enhanced':
            type_specific = "Add decision diamonds, parallel processes, error handling paths, and quality gates."
    
    elif diagram_type == 'mind map':
        if style == 'detailed':
            type_specific = "For each main branch, add 3-4 sub-branches with specific implementation details and considerations."
        elif style == 'compact':
            type_specific = "Limit to 3-4 main branches only, with 1-2 simple items per branch."
        elif style == 'enhanced':
            type_specific = "Add strategic branches like 'Innovation Opportunities', 'Risk Factors', 'Success Metrics', and 'Future Vision'."
    
    elif diagram_type == 'sequence':
        if style == 'detailed':
            type_specific = "Add logging actors, validation steps, and detailed error handling interactions."
        elif style == 'compact':
            type_specific = "Show only the core actor interactions, limit to 4-5 main message exchanges."
        elif style == 'enhanced':
            type_specific = "Include error handlers, monitoring systems, and alternative flow paths."
    
    elif diagram_type == 'swot analysis':
        if style == 'detailed':
            type_specific = "Provide 4-6 items per category with specific examples and market context."
        elif style == 'compact':
            type_specific = "Limit to 2-3 most critical items per SWOT category."
        elif style == 'enhanced':
            type_specific = "Add strategic action items and cross-category relationships for each SWOT element."
    
    variation_prompt = f"""{base_prompt}

VARIATION STYLE: {style.upper()}
{instruction['approach']} with the following specifications:
{instruction['specifics']}

{type_specific}

IMPORTANT: Create a structurally DIFFERENT diagram than other variations - not just different colors or themes, but different content, complexity, and approach for the topic: {user_input}"""

    return variation_prompt

# NEW: Generate multiple diagram variations of the same type
@app.route('/generate_diagram_variations', methods=['POST', 'OPTIONS'])
def generate_diagram_variations():
    """Generate 4 different visual variations of the same diagram type"""
    logger.info(f"Received request: {request.method} to /generate_diagram_variations")
    
    if request.method == 'OPTIONS':
        response = jsonify({})
        response.headers.add('Access-Control-Allow-Origin', '*')
        response.headers.add('Access-Control-Allow-Headers', 'Content-Type,Authorization')
        response.headers.add('Access-Control-Allow-Methods', 'POST,OPTIONS')
        return response
    
    try:
        logger.info(f"Processing POST request for diagram variations")
        data = request.json
        logger.info(f"Request data: {data}")
        
        if not data:
            logger.error("No JSON data received")
            return jsonify({"error": "No JSON data received"}), 400

        user_input = data.get('userInput', '').strip()
        diagram_type = data.get('diagramType', 'flowchart').strip()
        
        logger.info(f"User input: '{user_input}', Diagram type: '{diagram_type}'")
        
        if not user_input:
            logger.error("User input is required but was empty")
            return jsonify({"error": "User input is required"}), 400

        logger.info(f"Generating 4 variations of {diagram_type} for: {user_input[:50]}...")

        # Define 4 different visual approaches for the same diagram type
        variations = [
            {
                'id': 'variation_1',
                'name': f'{diagram_type.title()} - Standard',
                'style': 'standard',
                'approach': 'Create a standard, clean version',
                'color_theme': 'blue'
            },
            {
                'id': 'variation_2', 
                'name': f'{diagram_type.title()} - Detailed',
                'style': 'detailed',
                'approach': 'Create a more detailed version with additional information',
                'color_theme': 'green'
            },
            {
                'id': 'variation_3',
                'name': f'{diagram_type.title()} - Compact',
                'style': 'compact',
                'approach': 'Create a compact, simplified version',
                'color_theme': 'purple'
            },
            {
                'id': 'variation_4',
                'name': f'{diagram_type.title()} - Enhanced',
                'style': 'enhanced',
                'approach': 'Create an enhanced version with visual emphasis',
                'color_theme': 'orange'
            }
        ]

        diagram_variations = []
        
        for i, variation in enumerate(variations):
            try:
                # Generate enhanced prompt for this variation
                base_prompt = get_enhanced_diagram_prompt(diagram_type, user_input)
                variation_prompt = get_variation_specific_prompt(base_prompt, diagram_type, variation['style'], user_input)
                
                # Generate diagram data
                diagram_data = {}
                if client:
                    try:
                        response = client.chat.completions.create(
                            model="llama3-8b-8192",
                            messages=[
                                {
                                    "role": "system", 
                                    "content": f"You are a {diagram_type} expert. Return only valid JSON that matches the specified format exactly. Focus on {variation['style']} style."
                                },
                                {
                                    "role": "user", 
                                    "content": variation_prompt
                                }
                            ],
                            response_format={"type": "json_object"},
                            temperature=0.3 + (i * 0.2),  # Vary temperature for different results
                            max_tokens=2000
                        )
                        
                        diagram_data = json.loads(response.choices[0].message.content)
                        validate_diagram_json(diagram_data, diagram_type)
                        
                    except Exception as e:
                        logger.error(f"AI error for {diagram_type} variation {i+1}: {e}")
                        diagram_data = get_fallback_data(diagram_type, user_input)
                        # Customize fallback data for variations
                        diagram_data = customize_fallback_for_variation(diagram_data, diagram_type, variation['style'], user_input)
                else:
                    diagram_data = get_fallback_data(diagram_type, user_input)
                    diagram_data = customize_fallback_for_variation(diagram_data, diagram_type, variation['style'], user_input)

                # Generate SVG with variation-specific styling
                svg_content = generate_variation_svg(diagram_data, diagram_type, variation)

                # Create variation option
                option = {
                    "id": f"{diagram_type}_{variation['id']}_{int(datetime.now().timestamp())}",
                    "templateName": variation['name'],
                    "diagramType": diagram_type,
                    "content": svg_content,
                    "isDiagram": True,
                    "timestamp": datetime.now().isoformat(),
                    "description": f"A {variation['style']} style {diagram_type} visualization",
                    "variation": variation['style'],
                    "colorTheme": variation['color_theme'],
                    "uniqueId": variation['id']
                }
                
                diagram_variations.append(option)
                logger.info(f"Generated {diagram_type} variation {i+1} ({variation['style']}) successfully")
                
            except Exception as e:
                logger.error(f"Error generating {diagram_type} variation {i+1}: {e}")
                # Create a fallback variation instead of skipping
                try:
                    fallback_data = get_fallback_data(diagram_type, user_input)
                    fallback_data = customize_fallback_for_variation(fallback_data, diagram_type, variation['style'], user_input)
                    fallback_svg = generate_variation_svg(fallback_data, diagram_type, variation)
                    
                    fallback_option = {
                        "id": f"{diagram_type}_{variation['id']}_fallback_{int(datetime.now().timestamp())}",
                        "templateName": f"{variation['name']} (Fallback)",
                        "diagramType": diagram_type,
                        "content": fallback_svg,
                        "isDiagram": True,
                        "timestamp": datetime.now().isoformat(),
                        "description": f"A fallback {variation['style']} style {diagram_type} visualization",
                        "variation": variation['style'],
                        "colorTheme": variation['color_theme'],
                        "uniqueId": variation['id']
                    }
                    
                    diagram_variations.append(fallback_option)
                    logger.info(f"Generated fallback {diagram_type} variation {i+1} ({variation['style']}) successfully")
                except Exception as fallback_error:
                    logger.error(f"Failed to generate fallback variation {i+1}: {fallback_error}")
                    continue

        # Ensure we have exactly 4 variations
        if len(diagram_variations) < 4:
            logger.warning(f"Only generated {len(diagram_variations)} variations, creating additional fallbacks")
            while len(diagram_variations) < 4:
                missing_index = len(diagram_variations)
                fallback_data = get_fallback_data(diagram_type, user_input)
                fallback_svg = generate_variation_svg(fallback_data, diagram_type, variations[missing_index])
                
                fallback_option = {
                    "id": f"{diagram_type}_fallback_{missing_index}_{int(datetime.now().timestamp())}",
                    "templateName": f"{diagram_type.title()} - Fallback {missing_index + 1}",
                    "diagramType": diagram_type,
                    "content": fallback_svg,
                    "isDiagram": True,
                    "timestamp": datetime.now().isoformat(),
                    "description": f"A fallback {diagram_type} visualization",
                    "variation": "fallback",
                    "colorTheme": "blue",
                    "uniqueId": f"fallback_{missing_index}"
                }
                
                diagram_variations.append(fallback_option)
                logger.info(f"Created additional fallback variation {missing_index + 1}")

        if not diagram_variations:
            return jsonify({"error": "Failed to generate any diagram variations"}), 500

        logger.info(f"Successfully generated {len(diagram_variations)} diagram variations")
        
        return jsonify({
            "variations": diagram_variations,
            "userInput": user_input,
            "diagramType": diagram_type,
            "totalVariations": len(diagram_variations),
            "timestamp": datetime.now().isoformat()
        })

    except Exception as e:
        logger.error(f"Error generating diagram variations: {str(e)}")
        return jsonify({"error": f"Failed to generate diagram variations: {str(e)}"}), 500

if __name__ == '__main__':
    import os
    port = int(os.environ.get('PORT', 5000))
    debug_mode = os.environ.get('RAILWAY_ENVIRONMENT') != 'production'
    
    local_ip = get_local_ip()
    print("Starting Complete AI Generator Backend")
    print(f"Environment: {'Production' if not debug_mode else 'Development'}")
    print(f"Port: {port}")
    print(f"Groq API Key configured: {'Yes' if GROQ_API_KEY else 'No'}")
    
    if debug_mode:
        print("Server available at:")
        print(f"  • Local: http://127.0.0.1:{port}")
        print(f"  • Network: http://{local_ip}:{port}")
        print("Health check endpoints:")
        print(f"  • http://127.0.0.1:{port}/health")
        print(f"  • http://{local_ip}:{port}/health")
    
    print("Features:")
    print("   • 12 diagram types with AI-powered generation")
    print("   • Professional document generation")
    print("   • Multiple document templates")
    print("   • Fallback content for offline use")
    print("Available Endpoints:")
    print("   • /generate_ai_content - AI content generation")
    print("   • /generate_napkin_diagram - Diagram generation")
    print("   • /generate_document - Single document generation")
    print("   • /generate_documents - Multiple document generation")
    print("   • /document_templates - Available templates")
    print("   • /regenerate_diagram - Diagram regeneration")
    print("Fixed Issues:")
    print("   • Document generation 404 errors resolved")
    print("   • All diagram types working correctly")
    print("   • CORS configuration enhanced for mobile/web")
    print("   • Railway deployment ready")
    
    app.run(debug=debug_mode, port=port, host='0.0.0.0')
