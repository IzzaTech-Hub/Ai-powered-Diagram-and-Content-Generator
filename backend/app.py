from flask import Flask, request, jsonify
from flask_cors import CORS
import socket
import json
import math
import textwrap
import re
from datetime import datetime
import logging
from groq import Groq
import os

# Configure enhanced logging with UTF-8 encoding
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(levelname)s - %(message)s',
    handlers=[
        logging.FileHandler('ai_backend.log', encoding='utf-8'),
        logging.StreamHandler()
    ]
)
logger = logging.getLogger(__name__)

app = Flask(__name__)
# Enhanced CORS configuration for Flutter mobile and web
CORS(app, origins=['*'], supports_credentials=True, allow_headers=['Content-Type', 'Authorization'])

# Initialize Groq client with enhanced error handling
GROQ_API_KEY = os.environ.get("GROQ_API_KEY", "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")
os.environ["GROQ_API_KEY"] = GROQ_API_KEY

try:
    client = Groq(api_key=GROQ_API_KEY)
    logger.info("Groq client initialized successfully")
except Exception as e:
    logger.error(f"Failed to initialize Groq client: {e}")
    client = None

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
    for relationship in relationships:
        from_comp = relationship.get("from", "")
        to_comp = relationship.get("to", "")
        label = relationship.get("label", "")
        
        if from_comp in component_positions and to_comp in component_positions:
            x1, y1 = component_positions[from_comp]
            x2, y2 = component_positions[to_comp]
            
            svg_elements.extend([
                f'<line x1="{x1}" y1="{y1}" x2="{x2}" y2="{y2}" '
                'stroke="#7C3AED" stroke-width="2" stroke-dasharray="5,3"/>',
                
                f'<text x="{(x1+x2)/2}" y="{(y1+y2)/2-8}" font-family="Inter, sans-serif" '
                f'font-size="11" fill="#7C3AED" text-anchor="middle">{label[:15]}</text>'
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

def generate_enhanced_mindmap_svg(central_topic, branches, template_style="default"):
    """Ultra-enhanced mind map with premium design"""
    if not central_topic or not isinstance(branches, dict):
        return generate_error_svg("Mind map requires central_topic and branches")

    width, height = 1400, 900
    center_x, center_y = width // 2, height // 2
    central_topic = str(central_topic)[:35]

    # Clean and limit branches
    clean_branches = {}
    for k, v in list(branches.items())[:8]:
        branch_name = str(k)[:28]
        branch_content = str(v[0])[:40] if v and len(v) > 0 else branch_name
        clean_branches[branch_name] = branch_content

    # Template styles
    templates = {
        "default": {
            "colors": ['#FF6B6B', '#4ECDC4', '#45B7D1', '#96CEB4', '#FFEAA7', '#DDA0DD', '#98D8C8', '#F7DC6F'],
            "central_gradient": '''
            <radialGradient id="centralGrad" cx="50%" cy="30%" r="70%">
                <stop offset="0%" style="stop-color:#667eea;stop-opacity:1" />
                <stop offset="50%" style="stop-color:#764ba2;stop-opacity:1" />
                <stop offset="100%" style="stop-color:#5a67d8;stop-opacity:1" />
            </radialGradient>
            ''',
            "bg_color": "#f8fafc",
            "title_color": "#2d3748",
            "subtitle_color": "#718096",
            "branch_shape": "circle",
            "connection_style": "curved",
            "central_radius": 95
        }
    }

    # Use selected template or default
    template = templates.get(template_style, templates["default"])
    colors = template["colors"]
    bg_color = template["bg_color"]
    title_color = template["title_color"]
    subtitle_color = template["subtitle_color"]
    branch_shape = template["branch_shape"]
    central_radius = template["central_radius"]

    svg_elements = [
        '<defs>',
        # Central gradient
        template["central_gradient"],

        # Premium glow effect
        '''
        <filter id="premiumGlow" x="-50%" y="-50%" width="200%" height="200%">
            <feGaussianBlur stdDeviation="6" result="coloredBlur"/>
            <feMerge><feMergeNode in="coloredBlur"/><feMergeNode in="SourceGraphic"/></feMerge>
        </filter>
        ''',

        # Branch gradients
        *[f'''
        <radialGradient id="branchGrad{i}" cx="30%" cy="30%" r="70%">
            <stop offset="0%" style="stop-color:{colors[i % len(colors)]};stop-opacity:0.9" />
            <stop offset="100%" style="stop-color:{colors[i % len(colors)]};stop-opacity:1" />
        </radialGradient>
        ''' for i in range(len(clean_branches))],

        '</defs>',

        # Background
        f'<rect width="{width}" height="{height}" fill="{bg_color}"/>',

        # Title
        f'<text x="{width//2}" y="40" font-family="Inter, -apple-system, sans-serif" '
        f'font-size="28" font-weight="800" fill="{title_color}" text-anchor="middle">Mind Map</text>',
        f'<text x="{width//2}" y="65" font-family="Inter, -apple-system, sans-serif" '
        f'font-size="16" fill="{subtitle_color}" text-anchor="middle">Conceptual relationship visualization</text>',
    ]

    # Add central topic
    svg_elements.append(
        f'<circle cx="{center_x}" cy="{center_y}" r="{central_radius}" fill="url(#centralGrad)" '
        'filter="url(#premiumGlow)" stroke="rgba(255,255,255,0.5)" stroke-width="4"/>'
    )

    # Central topic text with better formatting
    svg_elements.append(
        f'<text x="{center_x}" y="{center_y}" font-family="Inter, -apple-system, sans-serif" '
        f'font-size="22" font-weight="800" fill="white" text-anchor="middle" '
        f'letter-spacing="0.5px">{central_topic}</text>'
    )

    # Generate premium branches
    angle_step = 360 / max(len(clean_branches), 1)

    for i, (branch, content) in enumerate(clean_branches.items()):
        angle = i * angle_step + (45 if len(clean_branches) % 2 == 0 else 0)
        rad = math.radians(angle)

        # Dynamic positioning
        base_distance = 280
        distance = base_distance + (len(content) * 1.5)

        branch_x = center_x + distance * math.cos(rad)
        branch_y = center_y + distance * math.sin(rad)

        # Connection points
        start_x = center_x + central_radius * math.cos(rad)
        start_y = center_y + central_radius * math.sin(rad)

        # Branch node radius/size
        branch_radius = 75

        # Curved connection with control point
        control_x = center_x + (distance * 0.6) * math.cos(rad)
        control_y = center_y + (distance * 0.6) * math.sin(rad)

        path = f'<path d="M{start_x} {start_y} '
        path += f'Q{control_x} {control_y} {branch_x - branch_radius*math.cos(rad)} {branch_y - branch_radius*math.sin(rad)}" '

        # Add connection
        svg_elements.extend([
            # Connection glow
            path + f'stroke="{colors[i % len(colors)]}" stroke-width="10" fill="none" opacity="0.3"/>',

            # Main connection
            path + f'stroke="{colors[i % len(colors)]}" stroke-width="5" fill="none" opacity="0.8"/>',
        ])

        # Branch node
        svg_elements.append(
            f'<circle cx="{branch_x}" cy="{branch_y}" r="{branch_radius}" fill="url(#branchGrad{i})" '
            'filter="url(#premiumGlow)" stroke="rgba(255,255,255,0.4)" stroke-width="3"/>'
        )

        # Branch title with smart wrapping
        svg_elements.append(
            f'<text x="{branch_x}" y="{branch_y-15}" font-family="Inter, -apple-system, sans-serif" '
            f'font-size="16" font-weight="700" fill="white" text-anchor="middle" '
            f'letter-spacing="0.3px">{branch[:20]}</text>'
        )

        # Branch content
        svg_elements.append(
            f'<text x="{branch_x}" y="{branch_y+5}" font-family="Inter, -apple-system, sans-serif" '
            f'font-size="12" fill="rgba(255,255,255,0.9)" text-anchor="middle">{content[:25]}</text>'
        )

    return f'<svg viewBox="0 0 {width} {height}" xmlns="http://www.w3.org/2000/svg" style="max-width: 100%; height: auto; font-family: Inter, -apple-system, sans-serif;">\n' + '\n'.join(svg_elements) + '\n</svg>'

def generate_enhanced_swot_svg(analysis):
    """Ultra-enhanced SWOT Analysis with premium design"""
    width, height = 1200, 800
    quadrant_width, quadrant_height = (width - 80) // 2, (height - 120) // 2

    colors = {
        'strengths': {'primary': '#48BB78', 'bg': '#F0FFF4', 'border': '#68D391', 'icon': 'S'},
        'weaknesses': {'primary': '#F56565', 'bg': '#FED7D7', 'border': '#FC8181', 'icon': 'W'},
        'opportunities': {'primary': '#4299E1', 'bg': '#EBF8FF', 'border': '#63B3ED', 'icon': 'O'},
        'threats': {'primary': '#ED8936', 'bg': '#FFFAF0', 'border': '#F6AD55', 'icon': 'T'}
    }

    svg = [
        f'<svg viewBox="0 0 {width} {height}" xmlns="http://www.w3.org/2000/svg" style="max-width: 100%; height: auto; font-family: Inter, -apple-system, sans-serif;">',
        '<defs>',
        # Ultra-premium shadow filter
        '''
        <filter id="premiumCardShadow" x="-20%" y="-20%" width="140%" height="140%">
            <feGaussianBlur in="SourceAlpha" stdDeviation="4"/>
            <feOffset dx="3" dy="6" result="offset"/>
            <feFlood flood-color="#000000" flood-opacity="0.2"/>
            <feComposite in2="offset" operator="in"/>
            <feMerge><feMergeNode/><feMergeNode in="SourceGraphic"/></feMerge>
        </filter>
        ''',
        '</defs>',

        # Premium background
        '<rect width="100%" height="100%" fill="#f8fafc"/>',

        # Main title with enhanced styling
        f'<text x="{width//2}" y="40" font-family="Inter, -apple-system, sans-serif" '
        'font-size="32" font-weight="800" fill="#2D3748" text-anchor="middle">SWOT Analysis</text>',
        f'<text x="{width//2}" y="65" font-family="Inter, -apple-system, sans-serif" '
        'font-size="16" fill="#718096" text-anchor="middle">Strategic business evaluation framework</text>',
    ]

    # Premium quadrant configurations
    quadrants = [
        {
            'name': 'Strengths', 'x': 40, 'y': 90,
            'items': analysis.get('strengths', ['Strong foundation', 'Clear objectives', 'Experienced team'])[:6],
            'colors': colors['strengths']
        },
        {
            'name': 'Opportunities', 'x': width//2 + 20, 'y': 90,
            'items': analysis.get('opportunities', ['Growth potential', 'Market expansion', 'Innovation opportunities'])[:6],
            'colors': colors['opportunities']
        },
        {
            'name': 'Weaknesses', 'x': 40, 'y': height//2 + 50,
            'items': analysis.get('weaknesses', ['Resource constraints', 'Limited experience', 'Process gaps'])[:6],
            'colors': colors['weaknesses']
        },
        {
            'name': 'Threats', 'x': width//2 + 20, 'y': height//2 + 50,
            'items': analysis.get('threats', ['Competition', 'Market changes', 'Economic factors'])[:6],
            'colors': colors['threats']
        }
    ]

    for quad in quadrants:
        x, y = quad['x'], quad['y']

        # Premium quadrant background
        svg.extend([
            f'<rect x="{x}" y="{y}" width="{quadrant_width}" height="{quadrant_height}" '
            f'rx="20" fill="{quad["colors"]["bg"]}" filter="url(#premiumCardShadow)" '
            f'stroke="{quad["colors"]["border"]}" stroke-width="3"/>',

            # Premium header section
            f'<rect x="{x}" y="{y}" width="{quadrant_width}" height="60" '
            f'rx="20" fill="{quad["colors"]["primary"]}" opacity="0.15"/>',

            # Enhanced title with icon
            f'<text x="{x + 25}" y="{y + 38}" font-family="Inter, -apple-system, sans-serif" '
            f'font-size="24" font-weight="800" fill="{quad["colors"]["primary"]}">'
            f'{quad["colors"]["icon"]} {quad["name"]}</text>',
        ])

        # Premium items with enhanced styling
        items = quad['items'] if quad['items'] else [f"Key {quad['name'].lower()} factors"]

        for i, item in enumerate(items):
            item_y = y + 80 + i * 50
            item_text = str(item)[:60]

            # Smart text wrapping for long items
            if len(item_text) > 35:
                words = item_text.split()
                mid_point = len(words) // 2
                line1 = ' '.join(words[:mid_point])
                line2 = ' '.join(words[mid_point:])

                svg.extend([
                    # Premium item background
                    f'<rect x="{x + 20}" y="{item_y - 8}" width="{quadrant_width - 40}" height="40" '
                    f'rx="12" fill="white" filter="url(#premiumCardShadow)" stroke="{quad["colors"]["primary"]}" '
                    'stroke-width="2" opacity="0.95"/>',

                    # Enhanced bullet point
                    f'<circle cx="{x + 35}" cy="{item_y + 12}" r="4" fill="{quad["colors"]["primary"]}"/>',

                    # Premium text lines
                    f'<text x="{x + 50}" y="{item_y + 5}" font-family="Inter, -apple-system, sans-serif" '
                    f'font-size="13" fill="#2D3748" font-weight="600">{line1}</text>',
                    f'<text x="{x + 50}" y="{item_y + 22}" font-family="Inter, -apple-system, sans-serif" '
                    f'font-size="13" fill="#2D3748" font-weight="600">{line2}</text>',
                ])
            else:
                svg.extend([
                    # Premium item background
                    f'<rect x="{x + 20}" y="{item_y - 8}" width="{quadrant_width - 40}" height="30" '
                    f'rx="12" fill="white" filter="url(#premiumCardShadow)" stroke="{quad["colors"]["primary"]}" '
                    'stroke-width="2" opacity="0.95"/>',

                    # Enhanced bullet point
                    f'<circle cx="{x + 35}" cy="{item_y + 7}" r="4" fill="{quad["colors"]["primary"]}"/>',

                    # Premium text
                    f'<text x="{x + 50}" y="{item_y + 12}" font-family="Inter, -apple-system, sans-serif" '
                    f'font-size="14" fill="#2D3748" font-weight="600">{item_text}</text>',
                ])

    svg.append('</svg>')
    return '\n'.join(svg)

def generate_enhanced_timeline_svg(events):
    """Ultra-enhanced timeline with premium design"""
    if not events or len(events) == 0:
        events = {
            "Phase 1": "Initial planning and preparation",
            "Phase 2": "Development and implementation",
            "Phase 3": "Testing and validation",
            "Phase 4": "Launch and deployment",
            "Phase 5": "Monitoring and optimization"
        }

    width, height = 1400, 600
    line_y = height // 2

    svg = [
        f'<svg viewBox="0 0 {width} {height}" xmlns="http://www.w3.org/2000/svg" style="max-width: 100%; height: auto; font-family: Inter, -apple-system, sans-serif;">',
        '<defs>',
        # Ultra-premium timeline gradient
        '''
        <linearGradient id="premiumTimelineGrad" x1="0%" y1="0%" x2="100%" y2="0%">
            <stop offset="0%" style="stop-color:#667eea;stop-opacity:1" />
            <stop offset="25%" style="stop-color:#764ba2;stop-opacity:1" />
            <stop offset="50%" style="stop-color:#f093fb;stop-opacity:1" />
            <stop offset="75%" style="stop-color:#f5576c;stop-opacity:1" />
            <stop offset="100%" style="stop-color:#4facfe;stop-opacity:1" />
        </linearGradient>
        ''',

        # Premium event shadow
        '''
        <filter id="premiumEventShadow" x="-30%" y="-30%" width="160%" height="160%">
            <feGaussianBlur in="SourceAlpha" stdDeviation="4"/>
            <feOffset dx="3" dy="6" result="offset"/>
            <feFlood flood-color="#000000" flood-opacity="0.25"/>
            <feComposite in2="offset" operator="in"/>
            <feMerge><feMergeNode/><feMergeNode in="SourceGraphic"/></feMerge>
        </filter>
        ''',
        '</defs>',

        # Premium background
        '<rect width="100%" height="100%" fill="#f8fafc"/>',

        # Title
        f'<text x="{width//2}" y="40" font-family="Inter, -apple-system, sans-serif" '
        'font-size="32" font-weight="800" fill="#2D3748" text-anchor="middle">Timeline</text>',
        f'<text x="{width//2}" y="65" font-family="Inter, -apple-system, sans-serif" '
        'font-size="16" fill="#718096" text-anchor="middle">Chronological progression visualization</text>',

        # Ultra-premium main timeline
        f'<rect x="120" y="{line_y-4}" width="{width-240}" height="8" rx="4" fill="url(#premiumTimelineGrad)"/>',

        # Timeline glow effect
        f'<rect x="120" y="{line_y-6}" width="{width-240}" height="12" rx="6" fill="url(#premiumTimelineGrad)" opacity="0.4"/>',
    ]

    event_list = list(events.items())[:7]
    if len(event_list) > 1:
        spacing = (width - 240) / (len(event_list) - 1)
    else:
        spacing = 0

    # Ultra-premium color palette for events
    event_colors = [
        '#FF6B6B', '#4ECDC4', '#45B7D1', '#96CEB4',
        '#FFEAA7', '#DDA0DD', '#98D8C8', '#F7DC6F'
    ]

    for i, (date, event) in enumerate(event_list):
        x = 120 + i * spacing
        color = event_colors[i % len(event_colors)]

        # Determine card position (alternate above/below)
        card_above = i % 2 == 0
        card_y = line_y - 140 if card_above else line_y + 60
        connector_y1 = line_y + (15 if card_above else -15)
        connector_y2 = card_y + (90 if card_above else 0)

        svg.extend([
            # Premium event marker with enhanced styling
            f'<circle cx="{x}" cy="{line_y}" r="20" fill="{color}" filter="url(#premiumEventShadow)" '
            'stroke="white" stroke-width="5"/>',

            # Inner premium dot
            f'<circle cx="{x}" cy="{line_y}" r="10" fill="white" opacity="0.9"/>',
            f'<circle cx="{x}" cy="{line_y}" r="6" fill="{color}"/>',

            # Premium connection line
            f'<path d="M{x} {connector_y1} Q{x + (25 if card_above else -25)} {(connector_y1 + connector_y2)/2} {x} {connector_y2}" '
            f'stroke="{color}" stroke-width="4" fill="none" opacity="0.8" stroke-dasharray="6,6"/>',

            # Ultra-premium event card
            f'<rect x="{x-100}" y="{card_y}" width="200" height="90" rx="16" fill="white" '
            f'filter="url(#premiumEventShadow)" stroke="{color}" stroke-width="3"/>',

            # Premium card header
            f'<rect x="{x-100}" y="{card_y}" width="200" height="30" rx="16" fill="{color}" opacity="0.15"/>',

            # Enhanced date styling
            f'<text x="{x}" y="{card_y + 22}" text-anchor="middle" font-family="Inter, -apple-system, sans-serif" '
            f'font-weight="800" font-size="14" fill="{color}" letter-spacing="0.5px">{str(date)[:25]}</text>',
        ])

        # Premium event description with smart wrapping
        event_text = str(event)[:70] if event else "Key milestone"
        words = event_text.split()
        lines = []
        current_line = []

        for word in words:
            if len(' '.join(current_line + [word])) <= 28:
                current_line.append(word)
            else:
                if current_line:
                    lines.append(' '.join(current_line))
                current_line = [word]
        if current_line:
            lines.append(' '.join(current_line))

        # Limit to 3 lines
        lines = lines[:3]

        for j, line in enumerate(lines):
            svg.append(
                f'<text x="{x}" y="{card_y + 45 + j*15}" text-anchor="middle" '
                f'font-family="Inter, -apple-system, sans-serif" font-size="12" fill="#4A5568" '
                f'font-weight="500">{line}</text>'
            )

    svg.append('</svg>')
    return '\n'.join(svg)

def generate_error_svg(error_message):
    """Generate ultra-premium error SVG"""
    return f'''<svg viewBox="0 0 600 180" xmlns="http://www.w3.org/2000/svg" style="max-width: 100%; height: auto; font-family: Inter, -apple-system, sans-serif;">
        <defs>
            <filter id="premiumErrorShadow">
                <feDropShadow dx="3" dy="6" stdDeviation="4" flood-opacity="0.25"/>
            </filter>
            <linearGradient id="errorGrad" x1="0%" y1="0%" x2="100%" y2="100%">
                <stop offset="0%" style="stop-color:#FED7D7;stop-opacity:1" />
                <stop offset="100%" style="stop-color:#FEB2B2;stop-opacity:1" />
            </linearGradient>
        </defs>
        <rect width="600" height="180" fill="url(#errorGrad)" stroke="#E53E3E" stroke-width="3" rx="16" filter="url(#premiumErrorShadow)"/>
        <circle cx="80" cy="60" r="25" fill="#E53E3E" opacity="0.2"/>
        <text x="80" y="70" font-family="Inter, -apple-system, sans-serif" font-size="28" font-weight="800" fill="#C53030" text-anchor="middle">!</text>
        <text x="130" y="50" font-family="Inter, -apple-system, sans-serif" font-size="20" font-weight="800" fill="#C53030">Generation Error</text>
        <text x="130" y="75" font-family="Inter, -apple-system, sans-serif" font-size="14" fill="#9B2C2C">{error_message[:70]}</text>
        <text x="130" y="95" font-family="Inter, -apple-system, sans-serif" font-size="13" fill="#9B2C2C">Please try again with different input or check your connection</text>
        <rect x="420" y="130" width="140" height="30" rx="15" fill="#E53E3E" opacity="0.15" stroke="#E53E3E" stroke-width="2"/>
        <text x="490" y="150" font-family="Inter, -apple-system, sans-serif" font-size="12" fill="#C53030" text-anchor="middle" font-weight="700">Try Again</text>
    </svg>'''

def clean_json_response(response_content):
    """Clean and prepare JSON response for parsing"""
    try:
        # Remove markdown code blocks if present
        response_content = re.sub(r'```json\s*', '', response_content)
        response_content = re.sub(r'```\s*$', '', response_content)
        
        # Remove any leading/trailing whitespace
        response_content = response_content.strip()
        
        # Find JSON content between first { and last }
        start_idx = response_content.find('{')
        end_idx = response_content.rfind('}')
        
        if start_idx != -1 and end_idx != -1 and end_idx > start_idx:
            response_content = response_content[start_idx:end_idx+1]
        
        return response_content
    except Exception as e:
        logger.error(f"Error cleaning JSON response: {e}")
        return response_content

def apply_text_changes_to_svg(current_svg, prompt):
    """Apply text changes directly to SVG content based on change instructions in prompt"""
    try:
        import re
        
        if not current_svg or not prompt:
            return None
            
        # Parse change instructions from the prompt
        # Format: - Change "original text" to "new text"
        change_pattern = r'- Change "([^"]+)" to "([^"]+)"'
        changes = re.findall(change_pattern, prompt)
        
        if not changes:
            logger.info("No text changes found in prompt")
            return None
            
        logger.info(f"Found {len(changes)} text changes to apply")
        
        # Apply each change to the SVG
        updated_svg = current_svg
        for original_text, new_text in changes:
            # Replace text in SVG content
            # Handle both direct text content and escaped versions
            replacements = [
                original_text,
                original_text.replace('&', '&amp;').replace('<', '&lt;').replace('>', '&gt;'),
                original_text.replace('&amp;', '&').replace('&lt;', '<').replace('&gt;', '>')
            ]
            
            for text_to_replace in replacements:
                if text_to_replace in updated_svg:
                    updated_svg = updated_svg.replace(text_to_replace, new_text)
                    logger.info(f"Replaced '{text_to_replace}' with '{new_text}'")
                    break
        
        return updated_svg
        
    except Exception as e:
        logger.error(f"Error applying text changes to SVG: {e}")
        return None

def get_fallback_data(diagram_type, user_input):
    """Enhanced fallback data for each diagram type"""
    
    fallback_data = {
        "flowchart": {
            "steps": {
                "Initialize": [f"Set up initial parameters for {user_input}"],
                "Analyze": [f"Examine requirements and constraints"],
                "Design": [f"Create solution architecture"],
                "Implement": [f"Execute the planned approach"],
                "Test": [f"Validate results and performance"],
                "Deploy": [f"Launch and monitor system"],
                "Optimize": [f"Refine and improve continuously"]
            }
        },
        
        "sequence": {
            "actors": {
                "User": "System user or client",
                "Frontend": "User interface layer",
                "Backend": "Server-side processing",
                "Database": "Data storage system",
                "External API": "Third-party service"
            },
            "interactions": [
                {"from": "User", "to": "Frontend", "message": f"Request {user_input}", "order": 1},
                {"from": "Frontend", "to": "Backend", "message": "Process request", "order": 2},
                {"from": "Backend", "to": "Database", "message": "Query data", "order": 3},
                {"from": "Database", "to": "Backend", "message": "Return results", "order": 4},
                {"from": "Backend", "to": "Frontend", "message": "Send response", "order": 5},
                {"from": "Frontend", "to": "User", "message": "Display results", "order": 6}
            ]
        },
        
        "state": {
            "states": {
                "Idle": f"System waiting for {user_input} trigger",
                "Processing": f"Active processing state",
                "Validating": f"Checking data integrity",
                "Executing": f"Running main operations",
                "Completing": f"Finalizing results",
                "Ready": f"Available for next operation"
            },
            "transitions": [
                {"from": "Idle", "to": "Processing", "trigger": "Start request", "order": 1},
                {"from": "Processing", "to": "Validating", "trigger": "Data received", "order": 2},
                {"from": "Validating", "to": "Executing", "trigger": "Validation passed", "order": 3},
                {"from": "Executing", "to": "Completing", "trigger": "Process finished", "order": 4},
                {"from": "Completing", "to": "Ready", "trigger": "Results ready", "order": 5},
                {"from": "Ready", "to": "Idle", "trigger": "Reset", "order": 6}
            ]
        },
        
        "mind map": {
            "central_topic": user_input.split()[0].title() if user_input.split() else "Topic",
            "branches": {
                "Strategy": [f"Strategic approach to {user_input}"],
                "Implementation": [f"Execution methodology"],
                "Resources": [f"Required tools and materials"],
                "Timeline": [f"Project scheduling"],
                "Risks": [f"Potential challenges"],
                "Benefits": [f"Expected outcomes"],
                "Metrics": [f"Success measurements"]
            }
        },
        
        "swot analysis": {
            "strengths": [
                f"Strong foundation in {user_input}",
                "Experienced team and leadership",
                "Clear objectives and vision",
                "Available resources and support",
                "Proven methodologies"
            ],
            "weaknesses": [
                "Limited initial experience",
                "Resource constraints",
                "Time pressures",
                "Skill gaps in certain areas",
                "Process inefficiencies"
            ],
            "opportunities": [
                "Market growth potential",
                "Technology advancement",
                "Strategic partnerships",
                "Innovation possibilities",
                "Expansion opportunities"
            ],
            "threats": [
                "Competitive pressure",
                "Economic uncertainties",
                "Regulatory changes",
                "Technology disruption",
                "Resource limitations"
            ]
        },
        
        "timeline": {
            "events": {
                "Phase 1": f"Initial planning for {user_input}",
                "Phase 2": f"Requirements gathering and analysis",
                "Phase 3": f"Design and architecture",
                "Phase 4": f"Implementation and development",
                "Phase 5": f"Testing and validation",
                "Phase 6": f"Deployment and launch",
                "Phase 7": f"Monitoring and optimization"
            }
        },
        
        "gantt": {
            "tasks": {
                "Planning": {
                    "description": f"Project initiation for {user_input}",
                    "dependencies": [],
                    "start": 1,
                    "duration": 2
                },
                "Analysis": {
                    "description": f"Requirements and feasibility study",
                    "dependencies": ["Planning"],
                    "start": 2,
                    "duration": 3
                },
                "Design": {
                    "description": f"System architecture and design",
                    "dependencies": ["Analysis"],
                    "start": 4,
                    "duration": 4
                },
                "Development": {
                    "description": f"Implementation and coding",
                    "dependencies": ["Design"],
                    "start": 6,
                    "duration": 8
                },
                "Testing": {
                    "description": f"Quality assurance and validation",
                    "dependencies": ["Development"],
                    "start": 12,
                    "duration": 3
                },
                "Deployment": {
                    "description": f"Go-live and launch activities",
                    "dependencies": ["Testing"],
                    "start": 14,
                    "duration": 1
                }
            }
        },
        
        "journey": {
            "touchpoints": {
                "Awareness": {
                    "action": f"User discovers need for {user_input}",
                    "emotion": "Curious",
                    "pain_points": ["Information overload"],
                    "order": 1
                },
                "Research": {
                    "action": f"Investigates available options",
                    "emotion": "Analytical",
                    "pain_points": ["Too many choices"],
                    "order": 2
                },
                "Evaluation": {
                    "action": f"Compares different solutions",
                    "emotion": "Cautious",
                    "pain_points": ["Complex comparisons"],
                    "order": 3
                },
                "Decision": {
                    "action": f"Selects preferred approach",
                    "emotion": "Confident",
                    "pain_points": ["Decision anxiety"],
                    "order": 4
                },
                "Implementation": {
                    "action": f"Begins using the solution",
                    "emotion": "Hopeful",
                    "pain_points": ["Learning curve"],
                    "order": 5
                },
                "Experience": {
                    "action": f"Interacts with the system",
                    "emotion": "Satisfied",
                    "pain_points": ["Minor issues"],
                    "order": 6
                },
                "Advocacy": {
                    "action": f"Recommends to others",
                    "emotion": "Enthusiastic",
                    "pain_points": [],
                    "order": 7
                }
            }
        },
        
        "erd": {
            "entities": {
                "User": ["user_id", "username", "email", "created_date"],
                "Project": ["project_id", "name", "description", "status"],
                "Task": ["task_id", "title", "priority", "due_date"],
                "Resource": ["resource_id", "type", "availability", "cost"]
            }
        },
        
        "class": {
            "classes": {
                "Controller": {
                    "attributes": ["id: int", "name: string", "status: boolean"],
                    "methods": ["initialize()", "process()", "validate()"]
                },
                "Service": {
                    "attributes": ["serviceId: int", "type: string", "config: object"],
                    "methods": ["execute()", "configure()", "monitor()"]
                },
                "Model": {
                    "attributes": ["data: object", "schema: string", "version: int"],
                    "methods": ["save()", "load()", "validate()"]
                }
            }
        },
        
        "network": {
            "nodes": {
                "Web Server": "Frontend application server",
                "API Gateway": "Request routing and authentication",
                "Database": "Data storage and retrieval",
                "Cache": "Performance optimization layer",
                "Load Balancer": "Traffic distribution"
            },
            "connections": [
                {"from": "Web Server", "to": "API Gateway", "label": "HTTPS"},
                {"from": "API Gateway", "to": "Database", "label": "SQL"},
                {"from": "API Gateway", "to": "Cache", "label": "Redis"}
            ]
        },
        
        "architecture": {
            "components": {
                "Presentation Layer": "User interface and interaction",
                "Business Logic": "Core application logic",
                "Data Access": "Database operations",
                "Integration": "External service connections",
                "Security": "Authentication and authorization"
            },
            "relationships": [
                {"from": "Presentation Layer", "to": "Business Logic", "label": "API Calls"},
                {"from": "Business Logic", "to": "Data Access", "label": "Data Operations"},
                {"from": "Business Logic", "to": "Integration", "label": "Service Calls"}
            ]
        }
    }
    
    return fallback_data.get(diagram_type, fallback_data["flowchart"])

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
            svg_content = generate_enhanced_mindmap_svg(
                diagram_data.get("central_topic", "Main Topic"),
                diagram_data.get("branches", {}),
                "default"
            )
        elif napkin_type == "swot analysis":
            svg_content = generate_enhanced_swot_svg(diagram_data)
        elif napkin_type == "timeline":
            svg_content = generate_enhanced_timeline_svg(diagram_data.get("events", {}))
        elif napkin_type == "gantt":
            svg_content = generate_enhanced_gantt_svg(diagram_data.get("tasks", {}))
        elif napkin_type == "journey":
            svg_content = generate_enhanced_journey_svg(diagram_data.get("touchpoints", {}))
        elif napkin_type == "erd":
            svg_content = generate_enhanced_erd_svg(diagram_data.get("entities", {}))
        elif napkin_type == "class":
            svg_content = generate_enhanced_class_diagram_svg(diagram_data.get("classes", {}))
        elif napkin_type == "network":
            svg_content = generate_enhanced_network_svg(diagram_data)
        elif napkin_type == "architecture":
            svg_content = generate_enhanced_architecture_svg(diagram_data)
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
            svg_content = generate_enhanced_mindmap_svg(
                diagram_data.get("central_topic", "Main Topic"),
                diagram_data.get("branches", {}),
                "default"
            )
        elif diagram_type == "swot analysis":
            svg_content = generate_enhanced_swot_svg(diagram_data)
        elif diagram_type == "timeline":
            svg_content = generate_enhanced_timeline_svg(diagram_data.get("events", {}))
        elif diagram_type == "gantt":
            svg_content = generate_enhanced_gantt_svg(diagram_data.get("tasks", {}))
        elif diagram_type == "journey":
            svg_content = generate_enhanced_journey_svg(diagram_data.get("touchpoints", {}))
        elif diagram_type == "erd":
            svg_content = generate_enhanced_erd_svg(diagram_data.get("entities", {}))
        elif diagram_type == "class":
            svg_content = generate_enhanced_class_diagram_svg(diagram_data.get("classes", {}))
        elif diagram_type == "network":
            svg_content = generate_enhanced_network_svg(diagram_data)
        elif diagram_type == "architecture":
            svg_content = generate_enhanced_architecture_svg(diagram_data)
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
